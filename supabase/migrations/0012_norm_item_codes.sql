-- 0012: Normalize item codes and re-sync items_code_seq.
-- CSV bulk inserts left items_code_seq out of sync (duplicate codes like
-- ITM-166 across several rows). Make codes deterministic and unique by
-- deriving them from the row id, then point the trigger sequence past the
-- highest id so future auto-generated codes cannot collide.

update public.items
   set code = 'ITM-' || lpad(id::text, 3, '0');

select setval('public.items_code_seq', greatest(coalesce((select max(id) from public.items), 1), 1), true);