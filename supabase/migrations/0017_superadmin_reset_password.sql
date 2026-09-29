-- 0017: Superadmin password reset for another account.
-- Called from the superadmin-only Pass Reset page via sb.rpc(). Works with the
-- public anon key (no service role needed) because the function is
-- security definer and only lets a SUPERADMIN caller reset a password.
-- Passwords are stored by GoTrue as bcrypt hashes (encrypted_password).

create or replace function public.admin_reset_password(target_username text, new_password text)
returns text
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  target_id uuid;
  target_name text;
begin
  if not exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'SUPERADMIN') then
    raise exception 'Only a superadmin can reset passwords';
  end if;

  if new_password is null or length(new_password) < 4 then
    raise exception 'Password must be at least 4 characters';
  end if;

  select au.id, au.email into target_id, target_name
  from auth.users au
  where au.email = target_username || '@ims.local'
  limit 1;

  if target_id is null then
    raise exception 'User not found';
  end if;

  update auth.users
     set encrypted_password = crypt(new_password, gen_salt('bf')),
         updated_at = now()
   where id = target_id;

  return target_username || ' reset';
end;
$$;

grant execute on function public.admin_reset_password(text, text) to anon, authenticated;