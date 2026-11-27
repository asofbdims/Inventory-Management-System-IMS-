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
set search_path = public, auth, extensions, pg_temp
as $$
declare
  v_username text;
  v_email text;
  v_name text;
  v_role text;
  v_user_id uuid;
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'SUPERADMIN'
  ) then
    raise exception 'Only a superadmin can create users';
  end if;

  v_username := lower(btrim(coalesce(p_username, '')));
  if v_username like '%@%' then
    if v_username !~ '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$' then
      raise exception 'Enter a valid email address';
    end if;
    v_email := v_username;
  else
    if v_username !~ '^[a-z0-9_.-]+$' then
      raise exception 'Login ID may contain only letters, numbers, dot, dash and underscore';
    end if;
    v_email := v_username || '@ims.local';
  end if;

  if p_password is null or length(p_password) < 6 then
    raise exception 'Password must be at least 6 characters';
  end if;

  v_name := btrim(coalesce(p_name, ''));
  if v_name = '' then
    raise exception 'Name is required';
  end if;

  v_role := upper(btrim(coalesce(p_role, '')));
  if v_role not in ('VIEW', 'CRUD') then
    raise exception 'Invalid role';
  end if;

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
    v_user_id, v_username, v_name, v_role, v_role, null, ''
  );

  return v_username;
end;
$$;

grant execute on function public.admin_create_user(text, text, text, text, bigint) to anon, authenticated;
