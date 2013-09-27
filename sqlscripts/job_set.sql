set linesize 300
set pagesize 500
set verify off

accept SCHEMA prompt "job owner schema (default all non-system schemas): "
accept JOBNAME prompt "job_name name (default all jobs): "
accept ENABLED prompt "enabled jobs only? (default yes): "
accept ATTR prompt "attribute to set: "
accept ATTRVAL prompt "value for attribute: "

--
-- generate stop job commands
--
select 'begin '||
          'DBMS_SCHEDULER.SET_ATTRIBUTE ('||
              'name => '''||owner||'.'||job_name||
              ''', attribute => '''||'&ATTR'||
              ''', value     => '||'&ATTRVAL'||
              '); '||
              chr(10)||
       'end;'||
       chr(10)||
       '/'
  from dba_scheduler_jobs
 where ( LOWER('&ENABLED') like 'n%'
         or
         enabled='TRUE'
       )
   and ( ('&SCHEMA' is null and owner not in ('SYS','SYSTEM'))
         or
         (owner = UPPER('&SCHEMA'))
       )
   and ( '&JOBNAME' is null or job_name = UPPER('&JOBNAME')
       )
 order by owner, job_name;
