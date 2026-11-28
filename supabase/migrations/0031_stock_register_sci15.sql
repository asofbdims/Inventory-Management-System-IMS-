alter table public.stock_register
  add column if not exists "sciFormId" bigint references public.sci_forms(id) on delete set null,
  add column if not exists "sciData" jsonb not null default '{}'::jsonb;

create index if not exists stock_register_sci_form_id_idx on public.stock_register ("sciFormId");
