-----------------------------------------------------------------------------
-- run as sysdba
-- script generates the "create synonym ...;" SQL commands for specified object
-- for which the specified users doesn't already have a synonym
-----------------------------------------------------------------------------

accept OBJOWNER prompt 'object owner: '
accept SYNOWNER prompt 'synonym owner (autorole, autouser to do all roles/users from schema_map): '
accept OBJECTNAME prompt 'object (default all): '

set pages 0
set linesize 140
set verify off
col syn format a140


select 'CREATE SYNONYM '||t.synowner||'.'||t.object_name||' FOR '||t.owner||'.'||t.object_name||';' as syn
  from (select d.object_type, d.owner, d.object_name, g.synowner
          from dba_objects d
         cross join
               (select UPPER('&SYNOWNER') as synowner from dual where upper('&SYNOWNER') not in ('AUTOROLE','AUTOUSER')
                union all
                select UPPER(s.name) from &OBJOWNER..schema_map s where s.type = 'role' and upper('&SYNOWNER') = 'AUTOROLE' and UPPER(s.name) <> UPPER('&OBJOWNER')
                union all
                select UPPER(s.name) from &OBJOWNER..schema_map s where s.type = 'user' and upper('&SYNOWNER') = 'AUTOUSER' and UPPER(s.name) <> UPPER('&OBJOWNER')
               ) g
         where d.owner = upper('&OBJOWNER')
           and (d.object_name= upper('&OBJECTNAME') or '&OBJECTNAME' IS NULL)
           and d.object_type not in ('INDEX', 'TRIGGER','LOB','PACKAGE BODY')
           and d.object_name not like 'BIN$%'
       ) t
  left outer join dba_synonyms s
    on (s.table_name = t.object_name
        and s.table_owner = upper('&OBJOWNER')
        and s.owner = t.synowner)
  where s.owner is null
 order by t.object_type, t.object_name, t.synowner;


set verify on
set pages 200
