accept tab prompt 'view fk constraints pointing to parent table: '

col owner form a20
col r_owner form a20
col table_name form a30
col constraint_name form a30
col r_constraint_name form a30
col r_columns form a30
col delete_rule form a20

select owner
       ,constraint_name
       ,constraint_type
       ,table_name
       ,r_owner
       ,r_constraint_name
       -- making assumption that all pk and uk have 10 or less columns...
       -- if wrong script will barf with ORA-01427: single-row subquery returns more than one row
       ,(select max(case when c.position=1 then c.column_name end) ||
		max(case when c.position=2 then ','||c.column_name end) ||
		max(case when c.position=3 then ','||c.column_name end) ||
		max(case when c.position=4 then ','||c.column_name end) ||
		max(case when c.position=5 then ','||c.column_name end) ||
		max(case when c.position=6 then ','||c.column_name end) ||
		max(case when c.position=7 then ','||c.column_name end) ||
		max(case when c.position=8 then ','||c.column_name end) ||
		max(case when c.position=9 then ','||c.column_name end) ||
		max(case when c.position=10 then ','||c.column_name end)
	   from all_cons_columns c 
	  where c.constraint_name=r_constraint_name) as r_columns
       ,delete_rule
  from all_constraints
 where constraint_type='R'
   and r_constraint_name in (select constraint_name
                               from all_constraints
                              where constraint_type in ('P','U') and table_name=upper('&tab'));


