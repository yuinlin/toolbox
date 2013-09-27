accept tab prompt 'view fk constraints on child table: '

col owner form a12
col r_owner form a12
col table_name form a20

select owner
       ,constraint_name
       ,constraint_type
       ,table_name
       ,r_owner
       ,r_constraint_name
       ,delete_rule
  from all_constraints 
 where constraint_type='R'
   and table_name=upper('&tab');
