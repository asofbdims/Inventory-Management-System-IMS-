-- Reset sequences for all tables with a serial "id" column to avoid
-- duplicate-key errors after manual/CSV inserts.
do $$
declare
  r record;
begin
  for r in
    select t.table_schema, t.table_name, c.column_name,
           pg_get_serial_sequence(t.table_schema||'.'||t.table_name, c.column_name) as seq
    from information_schema.columns c
    join information_schema.tables t
      on t.table_schema = c.table_schema and t.table_name = c.table_name
    where c.column_name = 'id'
      and c.table_schema = 'public'
      and t.table_type = 'BASE TABLE'
      and pg_get_serial_sequence(t.table_schema||'.'||t.table_name, c.column_name) is not null
  loop
    execute format('select setval(%L, (select max(id) from %I.%I))', r.seq, r.table_schema, r.table_name);
    raise notice 'fixed sequence %', r.seq;
  end loop;
end
$$;