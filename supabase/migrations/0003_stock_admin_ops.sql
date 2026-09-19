-- Stock register CRUD: admin-only delete policies for items and stock_items.
-- (Grants for delete already exist in 0002_grants.sql; these policies gate row access.)
-- Idempotent so it can be applied to an already-running local stack.
drop policy if exists "items_admin_delete" on public.items;
drop policy if exists "stock_admin_delete" on public.stock_items;
create policy "items_admin_delete" on public.items for delete to authenticated using (public.is_admin());
create policy "stock_admin_delete" on public.stock_items for delete to authenticated using (public.is_admin());