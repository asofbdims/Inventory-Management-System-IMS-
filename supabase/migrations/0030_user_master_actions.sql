create or replace function public.admin_update_user_password(
  p_username text,
  p_new_password text
)
returns text
language plpgsql
security definer
set search_path = public, auth, extensions, pg_temp
as $$
declare
  v_username text;
  v_user_id uuid;
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'SUPERADMIN'
  ) then
    raise exception 'Only a superadmin can change user passwords';
  end if;

  v_username := lower(btrim(coalesce(p_username, '')));
  if p_new_password is null or length(p_new_password) < 6 then
    raise exception 'Password must be at least 6 characters';
  end if;

  select p.id into v_user_id
  from public.profiles p
  where lower(p.username) = v_username;
  if v_user_id is null then
    raise exception 'User not found';
  end if;

  update auth.users
  set encrypted_password = crypt(p_new_password, gen_salt('bf')),
      updated_at = now()
  where id = v_user_id;

  return v_username;
end;
$$;

grant execute on function public.admin_update_user_password(text, text) to anon, authenticated;

create or replace function public.admin_delete_user(
  p_username text
)
returns text
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_username text;
  v_user_id uuid;
  v_role text;
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'SUPERADMIN'
  ) then
    raise exception 'Only a superadmin can delete users';
  end if;

  v_username := lower(btrim(coalesce(p_username, '')));
  select p.id, p.role into v_user_id, v_role
  from public.profiles p
  where lower(p.username) = v_username;
  if v_user_id is null then
    raise exception 'User not found';
  end if;
  if v_role = 'SUPERADMIN' then
    raise exception 'Superadmin account cannot be deleted';
  end if;

  delete from auth.users where id = v_user_id;

  return v_username;
end;
$$;

grant execute on function public.admin_delete_user(text) to anon, authenticated;
