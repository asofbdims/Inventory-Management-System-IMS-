-- 0023: Restart item code numbering from ITM-001 after clearing the Item Master,
-- and zero-pad codes below 1000 (no truncation above 999).

create or replace function public.items_assign_code()
returns trigger language plpgsql as $$
declare
  v bigint;
begin
  if new.code is null or new.code = '' then
    v := nextval('public.items_code_seq');
    new.code := 'ITM-' || case when v < 1000 then lpad(v::text, 3, '0') else v::text end;
  end if;
  return new;
end $$;

do $$
begin
  if not exists (select 1 from public.items) then
    perform setval('public.items_code_seq', 1, false);
  end if;
end $$;
