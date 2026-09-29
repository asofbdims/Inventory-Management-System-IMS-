-- 0010: Import support for the FY24-25 physical stock CSV.
-- Adds a unit column (qty + unit, e.g. "240 mtr"), the original raw quantity text
-- (qtyRaw) so nothing is lost during parsing, and a source tag so bulk imports
-- can be cleanly re-run (delete by source before re-inserting).
-- Also back-fills units for existing rows with '' and keeps difference generated.

alter table public.stock_register
  add column if not exists unit text not null default '',
  add column if not exists "qtyRaw" text not null default '',
  add column if not exists source text not null default '';

alter table public.stock_items
  add column if not exists unit text not null default '';