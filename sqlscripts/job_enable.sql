set linesize 300
set pagesize 500
set serveroutput on size 1000000

WHENEVER SQLERROR EXIT SQL.SQLCODE

accept SCHEMA prompt "job owner schema: "
accept JOBNAME prompt "job name (specific job name, BASE for base set, or null for all jobs): "

--
-- verify input schema
--
undefine job_owner
set verify off
col job_owner new_value job_owner
select username as job_owner from dba_users where username = UPPER('&SCHEMA');

begin
  if '&job_owner' IS NULL THEN
    raise_application_error (-20101, 'input schema '||'&SCHEMA'||' is invalid!');
  end if;
end;
/


--
-- generate enable commands
--
prompt ================================================
prompt run following commands to enable jobs:
select 'begin DBMS_SCHEDULER.ENABLE (name => '''||
       owner||
       '.'||
       job_name||
       '''); end;'||
       chr(10)||
       '/' as command
  from dba_scheduler_jobs
 where enabled <> 'TRUE'
   and owner = '&job_owner'
   and ( '&JOBNAME' is null or 
         (UPPER('&JOBNAME') <> 'BASE' and job_name = UPPER('&JOBNAME')) or
         (UPPER('&JOBNAME') = 'BASE' and job_name in ('CLEANUP_EVENT'
                                                      ,'CLEANUP_OUTSTANDING_BALANCE'
                                                      ,'CLEANUP_QUEUE'
                                                      ,'MOVE_TOURNAMENTS'))
       )
 order by job_name;


--
-- post job enable steps
--

prompt ================================================
prompt if job ACG_CALC_MEMBER_WINLOSS_DAILY was enabled
prompt please run the following to generate all historical winloss data:
prompt begin
prompt    &job_owner..pk_winloss.calc_memdailywinloss_all(<some day sufficiently far into past>,<sysdate at 00:00:05>);;
prompt end;;
prompt 
prompt for example:
prompt begin
prompt    &job_owner..pk_winloss.calc_memdailywinloss_all(SYSDATE - 100, trunc(sysdate) + interval '5' second);;
prompt end;;


set verify on