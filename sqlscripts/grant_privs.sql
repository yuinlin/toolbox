-----------------------------------------------------------------------------
-- run as sysdba
-- this script returns the "GRANT xxx ON xxx ...;" SQL commands for specified
-- objects owned by the specified owner whose privileges haven't been granted
-- to the specified grantee.
-----------------------------------------------------------------------------

accept OWNER prompt 'owner: '
accept GRANTEE prompt 'grantee (autorole, autouser to do all roles/users from schema_map): '
accept OBJECTNAME prompt 'object (default all): '

set pages 0
set linesize 120
set verify off
col grantpriv format a100

--
-- tables, materialized views
--
PROMPT ======== tables, materialized views
select 'GRANT SELECT ON &OWNER'||'.'||t.table_name||' TO '||t.grantee||';' as grantpriv
  from (select d.owner, d.table_name, g.grantee
          from dba_tables d
         cross join
               (select UPPER('&GRANTEE') as grantee from dual where upper('&GRANTEE') not in ('AUTOROLE','AUTOUSER')
                union all
                select UPPER(s.name) from &OWNER..schema_map s where s.type = 'role' and upper('&GRANTEE') = 'AUTOROLE' and UPPER(s.name) <> UPPER('&OWNER')
                union all
                select UPPER(s.name) from &OWNER..schema_map s where s.type = 'user' and upper('&GRANTEE') = 'AUTOUSER' and UPPER(s.name) <> UPPER('&OWNER')
               ) g
         where d.owner = upper('&OWNER')
           and (d.table_name= upper('&OBJECTNAME') or '&OBJECTNAME' IS NULL)
       ) t
  left outer join dba_tab_privs p
    on (p.table_name = t.table_name
        and p.owner = upper('&OWNER')
        and p.grantee = t.grantee
        and p.privilege = 'SELECT')
  where p.grantee is null
 order by t.table_name, t.grantee;


select 'GRANT INSERT,UPDATE,DELETE ON &OWNER'||'.'||t.table_name||' TO '||t.grantee||';' as grantpriv
  from (select d.owner, d.table_name, g.grantee
          from dba_tables d
         cross join
               (select UPPER('&GRANTEE') as grantee from dual where upper('&GRANTEE') not in ('AUTOROLE','AUTOUSER')
                union all
                select UPPER(s.name) from &OWNER..schema_map s where s.type = 'role' and upper('&GRANTEE') = 'AUTOROLE' and UPPER(s.name) <> UPPER('&OWNER')
                union all
                select UPPER(s.name) from &OWNER..schema_map s where s.type = 'user' and upper('&GRANTEE') = 'AUTOUSER' and UPPER(s.name) <> UPPER('&OWNER')
               ) g
         where d.owner = upper('&OWNER')
           and (d.table_name= upper('&OBJECTNAME') or '&OBJECTNAME' IS NULL)
           and not exists (select null
                             from dba_objects o
                            where o.object_name = d.table_name
                              and o.object_type = 'MATERIALIZED VIEW')
       ) t
  left outer join dba_tab_privs p
    on (p.table_name = t.table_name
        and p.owner = upper('&OWNER')
        and p.grantee = t.grantee
        and p.privilege <> 'SELECT')
  where p.grantee is null
 order by t.table_name, t.grantee;

--
-- views
--
PROMPT ======== views
select 'GRANT SELECT ON &OWNER'||'.'||t.view_name||' TO '||t.grantee||';' as grantpriv
  from (select d.owner, d.view_name, g.grantee
          from dba_views d
         cross join
               (select UPPER('&GRANTEE') as grantee from dual where upper('&GRANTEE') not in ('AUTOROLE','AUTOUSER')
                union all
                select UPPER(s.name) from &OWNER..schema_map s where s.type = 'role' and upper('&GRANTEE') = 'AUTOROLE' and UPPER(s.name) <> UPPER('&OWNER')
                union all
                select UPPER(s.name) from &OWNER..schema_map s where s.type = 'user' and upper('&GRANTEE') = 'AUTOUSER' and UPPER(s.name) <> UPPER('&OWNER')
               ) g
         where d.owner = upper('&OWNER')
           and (d.view_name= upper('&OBJECTNAME') or '&OBJECTNAME' IS NULL)
       ) t
  left outer join dba_tab_privs p
    on (p.table_name = t.view_name
        and p.owner = upper('&OWNER')
        and p.grantee = t.grantee
        and p.privilege = 'SELECT')
  where p.grantee is null
 order by t.view_name, t.grantee;

--
-- sequences
--
PROMPT ======== sequences
select 'GRANT SELECT ON &OWNER'||'.'||t.sequence_name||' TO '||t.grantee||';' as grantpriv
  from (select d.sequence_owner, d.sequence_name, g.grantee
          from dba_sequences d
         cross join
               (select UPPER('&GRANTEE') as grantee from dual where upper('&GRANTEE') not in ('AUTOROLE','AUTOUSER')
                union all
                select UPPER(s.name) from &OWNER..schema_map s where s.type = 'role' and upper('&GRANTEE') = 'AUTOROLE' and UPPER(s.name) <> UPPER('&OWNER')
                union all
                select UPPER(s.name) from &OWNER..schema_map s where s.type = 'user' and upper('&GRANTEE') = 'AUTOUSER' and UPPER(s.name) <> UPPER('&OWNER')
               ) g
         where d.sequence_owner = upper('&OWNER')
           and (d.sequence_name= upper('&OBJECTNAME') or '&OBJECTNAME' IS NULL)
       ) t
  left outer join dba_tab_privs p
    on (p.table_name = t.sequence_name
        and p.owner = upper('&OWNER')
        and p.grantee = t.grantee
        and p.privilege = 'SELECT')
  where p.grantee is null
 order by t.sequence_name, t.grantee;

--
-- procs
--
PROMPT ======== procedures
select 'GRANT EXECUTE ON &OWNER'||'.'||t.object_name||' TO '||t.grantee||';' as grantpriv
  from (select d.owner, d.object_name, g.grantee
          from dba_objects d
         cross join
               (select UPPER('&GRANTEE') as grantee from dual where upper('&GRANTEE') not in ('AUTOROLE','AUTOUSER')
                union all
                select UPPER(s.name) from &OWNER..schema_map s where s.type = 'role' and upper('&GRANTEE') = 'AUTOROLE' and UPPER(s.name) <> UPPER('&OWNER')
                union all
                select UPPER(s.name) from &OWNER..schema_map s where s.type = 'user' and upper('&GRANTEE') = 'AUTOUSER' and UPPER(s.name) <> UPPER('&OWNER')
               ) g
         where d.owner = upper('&OWNER')
           and (d.object_name= upper('&OBJECTNAME') or '&OBJECTNAME' IS NULL)
           and d.object_type in ('PROCEDURE','FUNCTION','PACKAGE')
       ) t
  left outer join dba_tab_privs p
    on (p.table_name = t.object_name
        and p.owner = upper('&OWNER')
        and p.grantee = t.grantee
        and p.privilege = 'EXECUTE')
  where p.grantee is null
 order by t.object_name, t.grantee;


set verify on
set pages 200


