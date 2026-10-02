-- 0018: Item master expansion.
--
-- Adds the extended catalogue fields for the improved Item Master page:
--   standardName, subcategory, unit, brand, model, status, createdAt.
-- RLS policies (0001) and table privileges (0002 grant on all tables)
-- already cover new columns, so no grant/policy changes are needed.
-- Idempotent so it can be applied to an already-running stack.

alter table public.items
  add column if not exists "standardName" text not null default '',
  add column if not exists subcategory text not null default '',
  add column if not exists unit text not null default '',
  add column if not exists brand text not null default '',
  add column if not exists model text not null default '',
  add column if not exists status text not null default 'Active',
  add column if not exists "createdAt" timestamptz not null default now();

update public.items
   set status = 'Active'
 where status = '' or status is null;