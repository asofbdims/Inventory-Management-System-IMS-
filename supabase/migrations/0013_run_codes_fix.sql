-- 0013: Re-apply item code normalization (0012 was recorded but statements
-- did not take effect). Codes are derived deterministically from the row id;
-- items_code_seq is set past the highest id so the trigger cannot collide.

update public.items
   set code = 'ITM-' || lpad(id::text, 3, '0');

select setval('public.items_code_seq', greatest(coalesce((select max(id) from public.items), 1), 1), true);

-- sentinel so we can confirm this migration actually executed remotely
insert into public.items (name, code)
values ('__SENTINEL_0013__', 'ITM-SENTINEL')
on conflict (name) do update set code = 'ITM-SENTINEL';