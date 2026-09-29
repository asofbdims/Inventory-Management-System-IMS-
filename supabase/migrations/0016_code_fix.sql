-- 0016: Make item codes full-length and collision-proof.
-- The auto-code trigger uses lpad(nextval,3), so once the sequence passes 999
-- codes truncate and collide (ITM-100 for id 100 and id 1000). Store the full
-- sequence value unpadded, re-derive existing codes from the row id, and drop
-- REST restore test rows.

create or replace function public.items_assign_code()
returns trigger language plpgsql as $$
begin
  if new.code is null or new.code = '' then
    new.code := 'ITM-' || nextval('public.items_code_seq')::text;
  end if;
  return new;
end $$;

drop trigger if exists items_code_before on public.items;
create trigger items_code_before
  before insert on public.items
  for each row execute function public.items_assign_code();

update public.items
   set code = 'ITM-' || id::text;

select setval('public.items_code_seq', greatest(coalesce((select max(id) from public.items), 1), 1), true);

delete from public.items where name in ('TEST-RESTORE-1', 'TEST-RESTORE-2');