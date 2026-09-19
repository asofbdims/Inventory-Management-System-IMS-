-- =============================================================
-- 0008: public storage bucket for hosting the IMS web app
-- (self-hosted static site on Supabase Storage CDN).
-- Idempotent.
-- =============================================================
insert into storage.buckets (id, name, public)
values ('ims-site', 'ims-site', true)
on conflict (id) do nothing;

drop policy if exists "ims_site_read" on storage.objects;
create policy "ims_site_read" on storage.objects
  for select using (bucket_id = 'ims-site');