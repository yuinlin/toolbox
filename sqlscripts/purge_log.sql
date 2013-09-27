--
-- view and purge dbms scheduler job log for specified job and days
--
set serveroutput on size 100000
set pagesize 600
set verify off

accept SCHEMA prompt "job owner schema (default current schema): "
accept JOBNAME prompt "job_name name (default all jobs currently defined for schema): "
accept KEEPDAYS prompt "history in days to keep (default 0): "

col job_owner new_value job_owner
select UPPER(NVL('&SCHEMA',sys_context('USERENV','SESSION_USER'))) as job_owner from dual;

col job_name form a40
prompt JOB LOGS PRE PURGE

select count(*), job_name 
  from dba_scheduler_job_log 
 where owner = '&job_owner'
   and ('&JOBNAME' is null or job_name = UPPER('&JOBNAME'))
 group by job_name 
 order by job_name
/

accept PURGE prompt "DO PURGE? (y/n): "

begin
  if NVL(UPPER('&purge'),'N') = 'Y' then
    for i in (select job_name 
                from dba_scheduler_jobs
               where owner = '&job_owner'
                 and ('&JOBNAME' is null or job_name = UPPER('&JOBNAME'))
             ) 
    loop
      DBMS_SCHEDULER.PURGE_LOG (log_history   => NVL('&KEEPDAYS',0)
                                ,which_log    => 'JOB_LOG'
                                ,job_name     => '&job_owner'||'.'||i.job_name
                               );     
    end loop;
    commit;
  else
    dbms_output.put_line ('');
    dbms_output.put_line ('== NO LOGS WERE PURGED ==');
  end if;
end;
/

prompt JOB LOGS POST PURGE

select count(*), job_name 
  from dba_scheduler_job_log 
 where owner = '&job_owner'
   and ('&JOBNAME' is null or job_name = UPPER('&JOBNAME'))
 group by job_name 
 order by job_name
/

set verify on
