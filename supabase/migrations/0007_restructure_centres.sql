-- =============================================================
-- Restructure centres: retire the POINT system.
-- New hierarchy = 18 Main Centres + 23 Sub-Centres (41 locations).
-- Idempotent: safe to re-run on any populated DB.
-- =============================================================

-- Remove any centre rows not part of the new hierarchy
-- (old POINT rows and renamed -S may include names like KASAN, BAHIN,
--  HASANPUR (FARIDABAD), BILASPUR (FARIDABAD), NUH, ...).
delete from public.centres
where id not in (select id from (values
  (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
  (11),(12),(13),(14),(15),(16),(17),(18),(19),(20),
  (21),(22),(23),(24),(25),(26),(27),(28),(29),(30),
  (31),(32),(33),(34),(35),(36),(37),(38),(39),(40),(41)
) v(id));

-- -------------------------------------------------------------
-- Main Centres (type CENTRE, parent null) — ids 1-18 kept stable
-- -------------------------------------------------------------
insert into public.centres (id, name, type, "parentId") values
  (1,  'ANKHEER',          'CENTRE', null),
  (2,  'BALLABGARH',       'CENTRE', null),
  (3,  'DLF CITY GURGAON', 'CENTRE', null),
  (4,  'TAORU',            'CENTRE', null),
  (5,  'FIROZPUR JHIRKA',  'CENTRE', null),
  (6,  'GURGAON',          'CENTRE', null),
  (7,  'MOHANA',           'CENTRE', null),
  (8,  'ZAIBABAD KHERLI',  'CENTRE', null),
  (9,  'NANGLA GUJRAN',    'CENTRE', null),
  (10, 'NIT - 2',          'CENTRE', null),
  (11, 'BAROLI',           'CENTRE', null),
  (12, 'HODAL',            'CENTRE', null),
  (13, 'PALWAL',           'CENTRE', null),
  (14, 'RAJENDRA PARK',    'CENTRE', null),
  (15, 'SECTOR-15-A',      'CENTRE', null),
  (16, 'PRITHLA',          'CENTRE', null),
  (17, 'SURAJ KUND',       'CENTRE', null),
  (18, 'TIGAON',           'CENTRE', null)
on conflict (id) do update set
  name = excluded.name,
  type = excluded.type,
  "parentId" = excluded."parentId";

-- -------------------------------------------------------------
-- Sub-Centres (type SUB CENTRE, parentId -> main centre) — ids 19-41
-- -------------------------------------------------------------
insert into public.centres (id, name, type, "parentId") values
  -- BALLABGARH (2)
  (19, 'MACHHGAR',             'SUB CENTRE', 2),
  -- DLF CITY GURGAON (3)
  (20, 'ABHEYPUR',             'SUB CENTRE', 3),
  (21, 'NUH',                  'SUB CENTRE', 3),
  (22, 'PUNAHANA',             'SUB CENTRE', 3),
  (23, 'SOHNA',                'SUB CENTRE', 3),
  -- GURGAON (6)
  (24, 'BADHA SIKENDERPUR',    'SUB CENTRE', 6),
  (25, 'BILASPUR',             'SUB CENTRE', 6),
  (26, 'BUDHERA',              'SUB CENTRE', 6),
  (27, 'DUNDAHERA',            'SUB CENTRE', 6),
  (28, 'FARUKH NAGAR',         'SUB CENTRE', 6),
  (29, 'JATAULA',              'SUB CENTRE', 6),
  (30, 'KASAN',                'SUB CENTRE', 6),
  (31, 'PATAUDI',              'SUB CENTRE', 6),
  -- MOHANA (7)
  (32, 'FATEHPUR BILLOCH',     'SUB CENTRE', 7),
  -- PALWAL (13)
  (33, 'BAHIN',                'SUB CENTRE', 13),
  (34, 'HASANPUR',             'SUB CENTRE', 13),
  (35, 'HATHIN',               'SUB CENTRE', 13),
  (36, 'MANDKOLA',             'SUB CENTRE', 13),
  (37, 'NAYAGAON',             'SUB CENTRE', 13),
  (38, 'SIHA',                 'SUB CENTRE', 13),
  -- SECTOR-15-A (15)
  (39, 'DHATIR',               'SUB CENTRE', 15),
  (40, 'GREATER FARIDABAD',    'SUB CENTRE', 15),
  -- TIGAON (18)
  (41, 'NACHAULI',             'SUB CENTRE', 18)
on conflict (id) do update set
  name = excluded.name,
  type = excluded.type,
  "parentId" = excluded."parentId";

-- -------------------------------------------------------------
-- Keep profile centreName in sync with the (possibly renamed) centres
-- -------------------------------------------------------------
update public.profiles p
set "centreName" = c.name
from public.centres c
where p."centreId" = c.id;