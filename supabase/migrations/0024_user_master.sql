-- 0024: Superadmin-only User Master (list + create users via public anon key).
create or replace function public.admin_list_users()
returns table (
  "authId" uuid,
  username text,
  name text,
  role text,
  "userType" text,
  "centreId" bigint,
  "centreName" text
)
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'SUPERADMIN'
  ) then
    raise exception 'Only a superadmin can view users';
  end if;

  return query
  select p.id, p.username, p.name, p.role, p."userType", p."centreId", p."centreName"
  from public.profiles p
  order by p."centreName", p.name;
end;
$$;

grant execute on function public.admin_list_users() to anon, authenticated;

create or replace function public.admin_create_user(
  p_username text,
  p_password text,
  p_name text,
  p_role text,
  p_centre_id bigint default null
)
returns text
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_username text;
  v_email text;
  v_name text;
  v_role text;
  v_centre_id bigint;
  v_centre_name text;
  v_user_type text;
  v_user_id uuid;
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'SUPERADMIN'
  ) then
    raise exception 'Only a superadmin can create users';
  end if;

  v_username := lower(btrim(coalesce(p_username, '')));
  if v_username !~ '^[a-z0-9_.-]+$' then
    raise exception 'Login ID may contain only letters, numbers, dot, dash and underscore';
  end if;

  if p_password is null or length(p_password) < 6 then
    raise exception 'Password must be at least 6 characters';
  end if;

  v_name := btrim(coalesce(p_name, ''));
  if v_name = '' then
    raise exception 'Name is required';
  end if;

  v_role := upper(btrim(coalesce(p_role, '')));
  if v_role not in ('CENTRE', 'ASO_VIEWER', 'SUPERADMIN') then
    raise exception 'Invalid role';
  end if;

  if v_role = 'CENTRE' then
    if p_centre_id is null then
      raise exception 'Centre is required for a CENTRE user';
    end if;
    select c.name into v_centre_name
    from public.centres c
    where c.id = p_centre_id;
    if v_centre_name is null then
      raise exception 'Centre not found';
    end if;
    v_centre_id := p_centre_id;
    v_user_type := 'CENTRE';
  else
    v_centre_id := null;
    v_centre_name := '';
    v_user_type := case v_role
      when 'SUPERADMIN' then 'ASO ADMIN'
      when 'ASO_VIEWER' then 'ASO VIEWER'
    end;
  end if;

  v_email := v_username || '@ims.local';
  if exists (select 1 from public.profiles p where lower(p.username) = v_username)
     or exists (select 1 from auth.users au where lower(au.email) = v_email) then
    raise exception 'Login ID already exists';
  end if;

  v_user_id := gen_random_uuid();
  insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  )
  values (
    '00000000-0000-0000-0000-000000000000'::uuid,
    v_user_id,
    'authenticated',
    'authenticated',
    v_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
    jsonb_build_object('name', v_name),
    now(),
    now()
  );

  insert into public.profiles (
    id, username, name, role, "userType", "centreId", "centreName"
  )
  values (
    v_user_id, v_username, v_name, v_role, v_user_type, v_centre_id, v_centre_name
  );

  return v_username;
end;
$$;

grant execute on function public.admin_create_user(text, text, text, text, bigint) to anon, authenticated;
