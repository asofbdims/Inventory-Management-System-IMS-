-- 0015: Store the full id in item codes (no lpad truncation).
-- lpad(id, 3) truncates ids >= 1000, so ids 106 / 1060 / 1065 all collapse to
-- ITM-106. Derive the code from the complete id so codes are unique, keep the
-- trigger sequence past the highest id, and drop probe/sentinel test rows.

update public.items
   set code = 'ITM-' || id::text;

select setval('public.items_code_seq', greatest(coalesce((select max(id) from public.items), 1), 1), true);

delete from public.items where name like '__%';