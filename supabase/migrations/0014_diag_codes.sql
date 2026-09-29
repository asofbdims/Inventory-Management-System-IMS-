do $$
declare
  n bigint;
  nn bigint;
begin
  select count(*) into n from public.items;
  raise notice 'before update: % rows in items', n;

  update public.items
     set code = 'ITM-' || lpad(id::text, 3, '0');
  get diagnostics n = row_count;
  raise notice 'updated % rows', n;

  perform setval('public.items_code_seq', greatest(coalesce((select max(id) from public.items), 1), 1), true);

  select count(*) into nn from public.items where code = 'ITM-' || lpad(id::text, 3, '0');
  raise notice 'rows now matching id-based code: %', nn;
end $$;