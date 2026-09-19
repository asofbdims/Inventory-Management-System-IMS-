-- 0004: stock register CRUD for every logged-in user.
-- Any authenticated user may add / rename / delete items and update stock
-- quantities and do cascade deletes ("manage for all logins" requirement).
-- Reads stay as-is; centres and SCI form status remain admin-only.
-- Idempotent so it can be applied to an already-running local stack.
drop policy if exists "items_admin_insert" on public.items;
drop policy if exists "items_admin_update" on public.items;
drop policy if exists "items_admin_delete" on public.items;
drop policy if exists "stock_admin_insert" on public.stock_items;
drop policy if exists "stock_admin_update" on public.stock_items;
drop policy if exists "stock_admin_delete" on public.stock_items;

create policy "items_insert_all" on public.items for insert to authenticated with check (auth.uid() is not null);
create policy "items_update_all" on public.items for update to authenticated using (auth.uid() is not null) with check (auth.uid() is not null);
create policy "items_delete_all" on public.items for delete to authenticated using (auth.uid() is not null);

create policy "stock_insert_all" on public.stock_items for insert to authenticated with check (auth.uid() is not null);
create policy "stock_update_all" on public.stock_items for update to authenticated using (auth.uid() is not null) with check (auth.uid() is not null);
create policy "stock_delete_all" on public.stock_items for delete to authenticated using (auth.uid() is not null);