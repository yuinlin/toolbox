-----------------------------------------------------------------------------
-- this script returns the "create public synonym ...;" SQL commands for all
-- objects owned by the user which don't currently have public synonyms.
--
-- note: this script is to be run by the schema owner, e.g. GIGAGAME.
--       but the "create public synonym ...;" commands resulting from 
--       this script need to be executed by a user with DBA or "create public
--       synonym" privileges
-----------------------------------------------------------------------------

set linesize 120
col syn format a100

select case when t.object_name is null then '======='||t.object_type||'======='
            else 'create public synonym '||t.object_name||' for '||user||'.'||t.object_name||';'
            end as syn
  from (select o.object_name
               ,o.object_type
          from all_synonyms s 
               ,(select object_name
                        ,min(object_type) 
                         keep (dense_rank first order by case when object_type ='MATERIALIZED VIEW' then 1 else 2 end)
                         as object_type
                   from user_objects 
                  where object_type not in ('INDEX', 'TRIGGER','LOB')
                    and object_name not like 'BIN$%'
                  group by object_name) o
         where s.table_owner(+) = user
           and o.OBJECT_NAME = s.TABLE_NAME (+)
           and s.synonym_name is null
         group by rollup (o.object_type, o.object_name)
         order by o.object_type, case when o.object_name is null then 0 else 1 end
       ) t;
