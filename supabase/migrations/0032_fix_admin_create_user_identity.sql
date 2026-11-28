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
  if v_role not in ('CENTRE', 'VIEW', 'CRUD') then
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
    v_user_type := v_role;
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
    confirmation_token,
    recovery_token,
    email_change,
    email_change_token_new,
    email_change_token_current,
    reauthentication_token,
    phone_change,
    phone_change_token,
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
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
    jsonb_build_object('name', v_name, 'email_verified', true),
    now(),
    now()
  );

  insert into auth.identities (
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  )
  values (
    v_user_id,
    jsonb_build_object('email', v_email, 'email_verified', true, 'phone_verified', false, 'sub', v_user_id::text),
    'email',
    v_user_id::text,
    now(),
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

insert into auth.identities (
  user_id,
  identity_data,
  provider,
  provider_id,
  last_sign_in_at,
  created_at,
  updated_at
)
select
  u.id,
  jsonb_build_object('email', u.email, 'email_verified', u.email_confirmed_at is not null, 'phone_verified', false, 'sub', u.id::text),
  'email',
  u.id::text,
  coalesce(u.last_sign_in_at, u.created_at, now()),
  coalesce(u.created_at, now()),
  coalesce(u.updated_at, now())
from auth.users u
where u.email is not null
  and not exists (
    select 1 from auth.identities i where i.user_id = u.id and i.provider = 'email'
  )
on conflict (provider_id, provider) do nothing;

update auth.users u
set confirmation_token = coalesce(u.confirmation_token, ''),
    recovery_token = coalesce(u.recovery_token, ''),
    email_change = coalesce(u.email_change, ''),
    email_change_token_new = coalesce(u.email_change_token_new, ''),
    email_change_token_current = coalesce(u.email_change_token_current, ''),
    reauthentication_token = coalesce(u.reauthentication_token, ''),
    phone_change = coalesce(u.phone_change, ''),
    phone_change_token = coalesce(u.phone_change_token, ''),
    raw_user_meta_data = coalesce(u.raw_user_meta_data, '{}'::jsonb) || jsonb_build_object('email_verified', true),
    updated_at = now()
where u.confirmation_token is null
   or u.recovery_token is null
   or u.email_change is null
   or u.email_change_token_new is null
   or u.email_change_token_current is null
   or u.reauthentication_token is null
   or u.phone_change is null
   or u.phone_change_token is null;
