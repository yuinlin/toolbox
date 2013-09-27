set linesize 300
set pagesize 500
set verify off

accept SCHEMA prompt "job owner schema (default all non-system schemas): "
accept JOBNAME prompt "job_name name (default all jobs, accepts wildcards): "
accept INC_ENABLED prompt "include enabled jobs? (y/n, default n): "
accept FORCE prompt "force drop? (y/n): "

--
-- generate stop job commands
--
select 'begin '||
           'DBMS_SCHEDULER.DROP_JOB (job_name => '''||
           owner||
           '.'||
           job_name||
           ''', force => '||
           (select case when upper('&FORCE') = 'Y' then 'TRUE' else 'FALSE' end from dual)||
           '); '||
           chr(10)||
       'exception when others then null; end;'||
       chr(10)||
       '/'
  from dba_scheduler_jobs 
 where ( ('&SCHEMA' is null and owner not in ('SYS','SYSTEM'))
         or
         (owner = UPPER('&SCHEMA'))
       )  
   and ( '&JOBNAME' is null or job_name like UPPER('&JOBNAME')
       )
   and ( (NVL(UPPER('&INC_ENABLED'),'N') = 'N' and enabled = 'FALSE')
         or
         (NVl(UPPER('&INC_ENABLED'),'N') = 'Y')
       )  
 order by owner, job_name;

