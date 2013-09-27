set linesize 300
set pagesize 500
set verify off

accept SCHEMA prompt "job owner schema (default all non-system schemas): "
accept JOBNAME prompt "job_name name (default all jobs): "
accept FORCE prompt "force stop? (y/n): "

--
-- generate stop job commands
--
select 'begin '||
          'begin '||
              'DBMS_SCHEDULER.STOP_JOB (job_name => '''||
              owner||
              '.'||
              job_name||
              ''', force => '||
              (select case when upper('&FORCE') = 'Y' then 'TRUE' else 'FALSE' end from dual)||
              '); '||
              chr(10)||
          'exception when others then null; end;'||
          chr(10)||
          'begin '||
              'DBMS_SCHEDULER.DISABLE (name => '''||
              owner||
              '.'||
              job_name||
              '''); '|| 
              chr(10)||
          'exception when others then null; end;'||             
       'end;'||
       chr(10)||
       '/'
  from dba_scheduler_jobs 
 where enabled='TRUE'
   and ( ('&SCHEMA' is null and owner not in ('SYS','SYSTEM'))
         or
         (owner = UPPER('&SCHEMA'))
       )  
   and ( '&JOBNAME' is null or job_name = UPPER('&JOBNAME')
       )
 order by owner, job_name;

