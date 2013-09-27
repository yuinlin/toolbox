set linesize 300
set pagesize 500
set verify off

accept SCHEMA prompt "job owner schema (default all non-system schemas): "
accept JOBNAME prompt "job_name name (default all jobs, accepts wildcard): "
accept REPTYPE prompt "report type (next, status, sched): "

-- save current nls session settings
col curr_nls_sort new_value curr_nls_sort
col curr_nls_comp new_value curr_nls_comp
select value as curr_nls_sort from nls_session_parameters where parameter = 'NLS_SORT';
select value as curr_nls_comp from nls_session_parameters where parameter = 'NLS_COMP';

-- set session
alter session set nls_timestamp_format='DD-MON-RR HH24:MI:SS';
alter session set nls_timestamp_tz_format='DD-MON-RR HH24:MI:SS TZH:TZM';
alter session set nls_sort = 'binary';
alter session set nls_comp = 'binary';


col owner form a12
col job_action form a50
col last_start_utc form a20
col next_run_utc form a20
col repeat_interval form a100

--
-- REPTYPE next_run: compare next run of enabled jobs with current time
--
select OWNER
       ,JOB_ACTION
       ,sys_extract_utc(LAST_START_DATE) as last_start_utc
       ,sys_extract_utc(NEXT_RUN_DATE) as next_run_utc
       ,REPEAT_INTERVAL
  from dba_scheduler_jobs 
 where LOWER('&REPTYPE') = 'next'
   and enabled='TRUE'
   and ( ('&SCHEMA' is null and owner not in ('SYS','SYSTEM'))
         or
         (owner = UPPER('&SCHEMA'))
       )  
   and ( '&JOBNAME' is null or job_name like UPPER('&JOBNAME')
       )
 order by sys_extract_utc(NEXT_RUN_DATE);

-- current utc time
select sys_extract_utc(systimestamp) as curr_time_utc from dual where LOWER('&REPTYPE') = 'next';


--
-- REPTYPE status: show enabled status, run and fail counts, and last runtime
--
col OWNER form a10
col ENABLED form a6
col RUN# form 9999999
col FAIL# form 9999999
col LAST_START_DATE form a28
col LAST_STATUS form a9
col JOB_NAME form a30
col JOB_ACTION form a50


select j.OWNER
       ,j.ENABLED
       ,j.RUN_COUNT as run#
       ,j.FAILURE_COUNT as fail#
       ,j.LAST_START_DATE
       ,(select t.status
           from (select l.owner
                        ,l.job_name
                        ,l.status 
                   from dba_scheduler_job_log l 
                  order by l.log_date desc) t
          where t.owner = j.owner
            and t.job_name = j.job_name
            and rownum = 1
        ) as last_status
       ,j.JOB_NAME
       ,j.JOB_ACTION
  from dba_scheduler_jobs j
 where LOWER('&REPTYPE') = 'status'
   and ( ('&SCHEMA' is null and j.owner not in ('SYS','SYSTEM'))
         or
         (j.owner = UPPER('&SCHEMA'))
       )  
   and ( '&JOBNAME' is null or j.job_name like UPPER('&JOBNAME')
       )
 order by j.owner, j.enabled, j.job_name;


--
-- REPTYPE sched: all about date/time for jobs
--
col OWNER form a10
col JOB_NAME form a40
col START_DATE form a28
col LAST_START_DATE form a28
col RUN_SEC form 99999.99
col NEXT_RUN_DATE form a28
col REPEAT_INTERVAL form a80

break on job_name skip 1

select OWNER
       ,decode(enabled,'FALSE','DISABLED: ')||JOB_NAME as job_name
       ,START_DATE
       ,LAST_START_DATE
       ,extract(hour from (last_run_duration)) * 60 *60 +
        extract(minute from (last_run_duration)) * 60 +
        extract(second from (last_run_duration)) as run_sec       
       ,NEXT_RUN_DATE
       ,REPEAT_INTERVAL
  from dba_scheduler_jobs 
 where LOWER('&REPTYPE') = 'sched'
   and ( ('&SCHEMA' is null and owner not in ('SYS','SYSTEM'))
         or
         (owner = UPPER('&SCHEMA'))
       )  
   and ( '&JOBNAME' is null or job_name like UPPER('&JOBNAME')
       )
 order by decode(enabled,'FALSE',1,2), owner, job_name;


set verify on
clear breaks

-- reset session nls setting
alter session set nls_sort = '&curr_nls_sort';
alter session set nls_comp = '&curr_nls_comp';
