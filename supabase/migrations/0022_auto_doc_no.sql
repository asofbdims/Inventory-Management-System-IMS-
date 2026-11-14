-- 0022: Auto-generate Document Master numbers (DOC-###), mirroring item codes.
-- The number is assigned by a DB trigger on insert, so the UI no longer needs a
-- manual "Enter number" + Save step. Existing rows are all blank, so every row
-- is renumbered in id order; future rows continue from the sequence.

create sequence if not exists public.documents_docno_seq start 1;

create or replace function public.documents_assign_docno()
returns trigger language plpgsql as $$
begin
  if new."docNo" is null or new."docNo" = '' then
    new."docNo" := 'DOC-' || to_char(nextval('public.documents_docno_seq'), 'FM000');
  end if;
  return new;
end $$;

drop trigger if exists documents_docno_before on public.documents;
create trigger documents_docno_before
  before insert on public.documents
  for each row execute function public.documents_assign_docno();

with ranked as (
  select id, row_number() over (order by id) as rn
  from public.documents
)
update public.documents d
   set "docNo" = 'DOC-' || to_char(ranked.rn, 'FM000')
  from ranked
 where d.id = ranked.id;

select setval(
  'public.documents_docno_seq',
  greatest((select count(*) from public.documents), 1),
  (select count(*) from public.documents) > 0
);
