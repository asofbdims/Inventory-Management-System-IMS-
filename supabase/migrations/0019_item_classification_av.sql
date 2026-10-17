-- Migration 0019: Add classification and AV/sensitive details to items
-- Backward compatible, idempotent

alter table public.items
  add column if not exists classification text not null default 'unclassified',
  add column if not exists is_sensitive boolean not null default false,
  add column if not exists asset_tag text,
  add column if not exists serial_no text,
  add column if not exists location text,
  add column if not exists custodian text,
  add column if not exists condition text,
  add column if not exists acquisition_date date,
  add column if not exists acquisition_value numeric(14,2),
  add column if not exists depreciation_method text,
  add column if not exists warranty_expiry date,
  add column if not exists remarks text;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'items_classification_check'
      and conrelid = 'public.items'::regclass
  ) then
    alter table public.items
      add constraint items_classification_check
      check (classification in ('capital','general','unclassified'));
  end if;
end$$;

create index if not exists idx_items_classification on public.items(classification);
create index if not exists idx_items_sensitive on public.items(is_sensitive);
create unique index if not exists idx_items_asset_tag_unique
  on public.items(asset_tag)
  where asset_tag is not null and asset_tag <> '';

comment on column public.items.classification is 'Item classification: capital, general, or unclassified (explicit).';
comment on column public.items.is_sensitive is 'Flag for AV/sensitive items.';
comment on column public.items.asset_tag is 'Asset tag/identifier for sensitive items.';
comment on column public.items.serial_no is 'Primary serial number for the item/asset.';
comment on column public.items.location is 'Physical location of the item/asset.';
comment on column public.items.custodian is 'Custodian/responsible person.';
comment on column public.items.condition is 'Condition (e.g. New, Good, Fair, Repair, Condemned).';
comment on column public.items.acquisition_date is 'Date of acquisition.';
comment on column public.items.acquisition_value is 'Acquisition cost/value.';
comment on column public.items.depreciation_method is 'Depreciation method if tracked.';
comment on column public.items.warranty_expiry is 'Warranty expiry date.';
comment on column public.items.remarks is 'Additional notes for AV/sensitive items.';
