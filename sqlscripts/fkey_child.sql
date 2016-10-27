accept tab prompt 'view fk constraints on child table: '
accept reftab prompt 'show only constraints referencing table (default all): '

col owner form a12
col r_owner form a12
col table_name form a20
col columns form a60

select r.owner
       ,r.constraint_name
       ,r.table_name
       ,LISTAGG(c.column_name, ',') WITHIN GROUP (ORDER BY c.position) as columns
       ,r.r_owner
       ,k.table_name
       ,r.r_constraint_name
       ,r.delete_rule
  from all_constraints r
  join all_cons_columns c
    on (c.constraint_name = r.constraint_name)
  join all_constraints k
    on (k.constraint_name = r.r_constraint_name)
 where r.constraint_type='R'
   and r.table_name=upper('&tab')
   and ('&reftab' is null
        or
        k.table_name=upper('&reftab'))
 group by r.owner, r.constraint_name, r.table_name, r.r_owner, k.table_name, r.r_constraint_name, r.delete_rule;

