accept table prompt 'table name: '
accept schema prompt 'owner if not current user: '

col name format a30
col type format a20
col owner format a30 new_value owner

select upper(nvl('&schema', user)) as owner from dual;

select name
       ,type
       ,owner
  from (select name
               ,type
               ,owner
          from all_dependencies
         where referenced_owner = UPPER('&owner')
           and referenced_name = UPPER('&table')
         union all
        select (select table_name 
                  from all_constraints 
                 where constraint_type='P' 
                   and constraint_name = f.r_constraint_name
                   and table_name <> f.table_name) as name
               ,'TABLE' as type
               ,f.r_owner as owner
          from all_constraints f
         where f.owner = UPPER('&owner')
           and f.table_name = UPPER('&table')
           and f.r_constraint_name is not null)
 where name is not null;

undefine 1
undefine 2 
undefine schema
undefine table
undefine owner

