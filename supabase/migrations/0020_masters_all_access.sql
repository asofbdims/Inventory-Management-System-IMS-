-- 0020: Grant full Masters access (Centre/Document) to all authenticated users
-- Align with items/stock (0004) and enable Centre Master add/edit/delete and Document Master full CRUD for centres.

-- Centres
drop policy if exists "centres_admin_insert" on public.centres;
drop policy if exists "centres_admin_update" on public.centres;
drop policy if exists "centres_admin_delete" on public.centres;

create policy "centres_insert_all" on public.centres for insert to authenticated with check (auth.uid() is not null);
create policy "centres_update_all" on public.centres for update to authenticated using (auth.uid() is not null) with check (auth.uid() is not null);
create policy "centres_delete_all" on public.centres for delete to authenticated using (auth.uid() is not null);

-- Documents
drop policy if exists "documents_delete_admin" on public.documents;

create policy "documents_delete_all" on public.documents for delete to authenticated using (auth.uid() is not null);
