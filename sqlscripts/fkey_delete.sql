accept tab prompt 'generate delete for all children of table: '

col table_name form a30

with 
  children (owner,table_name,table_pk,clevel)  as
  (
    select fk.owner
           ,fk.table_name
           ,pk.constraint_name as table_pk
           ,0 as clevel
      from all_constraints fk
      left outer join all_constraints pk
        on (pk.owner = fk.owner and
            pk.table_name = fk.table_name and
            pk.constraint_type in ('P','U')
            )
     where fk.constraint_type='R'
       and fk.r_constraint_name in (select constraint_name
                                      from all_constraints 
                                     where constraint_type in ('P','U') and table_name=upper('&tab'))
     union all
    select fk.owner
           ,fk.table_name
           ,pk.constraint_name as table_pk
           ,c.clevel + 1
      from all_constraints fk
      join children c
        on (fk.constraint_type='R' and
            fk.r_owner = c.owner and
            fk.r_constraint_name = c.table_pk)
      left outer join all_constraints pk
        on (pk.owner = fk.owner and
            pk.table_name = fk.table_name and
            pk.constraint_type in ('P','U')
            )
  )
  cycle table_name set is_cycle to '1' default '0' 
select 'delete '||table_name||';'
  from children
 group by table_name
 order by max(case when is_cycle = '1' then '0' else to_char(clevel) end) desc;
