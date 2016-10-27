accept tab prompt 'view all children of table: '

col owner form a20
col r_owner form a20
col table_name form a30
col table_pk form a30
col constraint_name form a30
col r_constraint_name form a30
col delete_rule form a12
col clevel form 999

with
  children (owner,constraint_name,table_name,table_pk,r_owner,r_constraint_name,delete_rule,clevel)  as
  (
    select fk.owner
           ,fk.constraint_name
           ,fk.table_name
           ,pk.constraint_name as table_pk
           ,fk.r_owner
           ,fk.r_constraint_name
           ,fk.delete_rule
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
           ,fk.constraint_name
           ,fk.table_name
           ,pk.constraint_name as table_pk
           ,fk.r_owner
           ,fk.r_constraint_name
           ,fk.delete_rule
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
select *
  from children;

