-- 0005: remove duplicate centre rows (points/centres) that share name+parent+type.
-- Before deleting, sync any linked data from a duplicate id onto the kept (min id):
--   * stock_items -> summed on conflict ("centreId", item)
--   * sci_forms."centreId" / "destinationCentreId"
--   * profiles."centreId"
--   * children whose "parentId" points at a duplicate -> re-parented to kept id
-- Idempotent: if there are no duplicates it is a safe no-op.
-- A unique index then guarantees duplicates can never be created again.

create temp table _dup as
with d as (
  select name, coalesce("parentId", 0) as p, type, min(id) as keep_id
  from public.centres
  group by name, coalesce("parentId", 0), type
  having count(*) > 1
)
select c.id as dup, d.keep_id
from public.centres c
join d on c.name = d.name and coalesce(c."parentId", 0) = d.p and c.type = d.type
where c.id <> d.keep_id;

-- 1) merge stock: sum quantities onto the kept centre, then remove the moved rows
insert into public.stock_items ("centreId", item, qty)
select d.keep_id, s.item, s.qty
from public.stock_items s
join _dup d on s."centreId" = d.dup
on conflict ("centreId", item) do update set qty = public.stock_items.qty + excluded.qty;

delete from public.stock_items s using _dup d where s."centreId" = d.dup;

-- 2) sync sci_forms references
update public.sci_forms f set "centreId" = d.keep_id from _dup d where f."centreId" = d.dup;
update public.sci_forms f set "destinationCentreId" = d.keep_id from _dup d where f."destinationCentreId" = d.dup;

-- 3) sync profiles references
update public.profiles p set "centreId" = d.keep_id from _dup d where p."centreId" = d.dup;

-- 4) re-parent any children of a duplicate to its kept id
update public.centres c set "parentId" = d.keep_id from _dup d where c."parentId" = d.dup;

-- 5) delete the duplicate centre rows
delete from public.centres c using _dup d where c.id = d.dup;

drop table _dup;

-- 6) prevent recurrence
create unique index if not exists uniq_centres_name_parent_type
  on public.centres (name, coalesce("parentId", 0), type);