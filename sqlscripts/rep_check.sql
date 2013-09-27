set linesize 300
set pagesize 500
set verify off

accept SCHEMA prompt "report owner schema: "
accept REPNAME prompt "report name (default all reports, accepts wildcard): "
accept CHECKTYPE prompt "check type (status, file, job, sent): "

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

--
-- CHECKTYPE status: info related to whether report is valid for current environment
--
col SITE form 99999
col REPORT_NAME form a32
col DIRECTORY_NAME form a30
col REP_SCHEMAS form a20
col CURR_SCHEMA form a20
col REP_DATABASES form a20
col CURR_DATABASE form a20
col STATUS form a30
col JOB_ENABLED form a11

select t.site
       ,t.report_name
       ,t.directory_name
       ,t.rep_schemas
       ,t.curr_schema
       ,t.rep_databases
       ,t.curr_database
       ,nvl(&SCHEMA..pk_report3.validate_report(t.site, t.report_name),'ERROR validating report!') as STATUS
       ,nvl((select j.enabled from all_scheduler_jobs j where lower(j.owner) = lower('&SCHEMA') and j.job_name = t.scheduler_job_name),'NO JOB') as JOB_ENABLED
  from (select s.site_id as site
               ,s.report_name
               ,s.directory_name
               ,s.scheduler_job_name
               ,lower(s.valid_schemas) as rep_schemas
               ,lower('&SCHEMA') as curr_schema
               ,lower(s.valid_databases) as rep_databases
               ,lower(sys_context('userenv','db_name')) as curr_database
          from &SCHEMA..site_report_attributes s
         where LOWER('&CHECKTYPE') = 'status'
           and ( ('&REPNAME' is null)
                 or
                 UPPER(s.report_name) like UPPER('&REPNAME')
               )
       ) t
 order by t.site, t.report_name;

--
-- CHECKTYPE file: info related to report file name, location, formats
--
col SITE form 99999
col REPORT_NAME form a32
col DIRECTORY_NAME form a30
col FILE_NAME form a36
col FORMATS form a86
col LAST_GENERATED form a25

select case when d.rno = 1 then s.site_id end as site
       ,case when d.rno = 1 then s.report_name end as report_name
       ,case when d.rno = 1 then s.directory_name end as directory_name
       ,case when d.rno = 1 then s.file_name end as file_name
       ,case when d.rno = 1 then 'sbj form: '||s.subject_format
             when d.rno = 2 then 'sbj     : '||s.subject
             when d.rno = 3 then 'att form: '||s.attach_name_format
             when d.rno = 4 then 'att     : '||s.attach_name
             when d.rno = 5 then 'bdy form: '||s.body_text_format
             when d.rno = 6 then 'bdy     : '||s.body_text
             end as formats
       ,case when d.rno = 1 then s.last_generated end as last_generated
  from &SCHEMA..site_report_attributes s
 cross join (select rownum as rno from dual connect by level < 7) d
 where LOWER('&CHECKTYPE') = 'file'
   and ( ('&REPNAME' is null)
         or
         UPPER(s.report_name) like UPPER('&REPNAME')
       )
 order by s.site_id, s.report_name, d.rno;

--
-- CHECKTYPE sent: info related to sending report
--
col SITE form 99999
col REPORT_NAME form a32
col DIRECTORY_NAME form a30
col FILE_NAME form a40
col LAST_GENERATED form a25
col LAST_SENT form a25
col EMAIL_ID form 999
col SENDER_ADDRESS form a14
col RECIP_ADDRESS form a26
col BODY_MIMETYPE form a30
col ATTACH_MIMETYPE form a20
col INLINE form 9

select case when t.rno = 1 then t.site_id else null end as site
       ,case when t.rno = 1 then t.report_name else null end as report_name
       ,case when t.rno = 1 then t.last_generated else null end as last_generated
       ,case when t.rno = 1 then t.last_sent else null end as last_sent
       ,case when t.rno = 1 then t.email_id else null end as email_id
       ,case when t.rno = 1 then t.sender_address else null end as sender_address
       ,case when t.xto = 1 then 'to: ' when t.cc = 1 then 'cc: ' when t.bcc = 1 then 'bcc: ' end||t.recip_address as recip_address
       ,case when t.rno = 1 then t.body_mimetype else null end as body_mimetype
       ,case when t.rno = 1 then t.attach_mimetype else null end as attach_mimetype
       ,case when t.rno = 1 then t.attach_inline else null end as inline
  from (select s.site_id
               ,s.report_name
               ,s.directory_name
               ,s.file_name
               ,s.last_generated
               ,s.last_sent
               ,s.email_id
               ,e.sender_address
               ,e.body_mimetype
               ,e.attach_mimetype
               ,e.attach_inline
               ,e.mime_from
               ,e.mime_to
               ,e.mime_cc
               ,e.mime_bcc
               ,r.recip_address
               ,r.xto
               ,r.cc
               ,r.bcc
               ,row_number () over (partition by s.site_id, s.report_name order by case when r.xto = 1 then 1 when r.cc = 1 then 2 else 3 end) as rno
          from &SCHEMA..site_report_attributes s
          left join &SCHEMA..email_attributes e
            on (s.email_id = e.email_id)
          left join &SCHEMA..email_recipients r
            on (r.email_id = e.email_id)
         where LOWER('&CHECKTYPE') = 'sent'
           and ( ('&REPNAME' is null)
                 or
                 UPPER(s.report_name) like UPPER('&REPNAME')
               )
       ) t
 order by t.site_id, t.report_name, t.rno;

--
-- CHECKTYPE job: info related to report job
--
col SITE form 99999
col REPORT_NAME form a32
col JOB_NAME form a30
col JOB_ACTION form a46
col "EXISTS?" form a7
col "ENABLED?" form a8
col LAST_START_DATE form a25
col LAST_STATUS form a9
col REP_LAST_GENERATED form a25
col REP_LAST_SENT form a25


select s.site_id as site
       ,s.report_name
       ,s.scheduler_job_name as job_name
       ,j.job_action
       ,case when j.job_name is not null then 'YES' else 'NO' end as "EXISTS?"
       ,j.enabled as "ENABLED?"
       ,j.last_start_date
       ,(select t.status
           from (select l.owner
                        ,l.job_name
                        ,l.status
                   from all_scheduler_job_log l
                  order by l.log_date desc) t
          where t.owner = j.owner
            and t.job_name = j.job_name
            and rownum = 1
        ) as last_status
       ,s.last_generated as rep_last_generated
       ,s.last_sent as rep_last_sent
  from &SCHEMA..site_report_attributes s
  left join all_scheduler_jobs j
    on (lower(j.owner) = lower('&SCHEMA') and
        j.job_name = s.scheduler_job_name)
 where LOWER('&CHECKTYPE') = 'job'
   and ( ('&REPNAME' is null)
         or
         UPPER(s.report_name) like UPPER('&REPNAME')
       )
 order by s.site_id, s.report_name;


-- current time with TZ
select systimestamp as curr_time from dual;


set verify on
clear breaks

-- reset session nls setting
alter session set nls_sort = '&curr_nls_sort';
alter session set nls_comp = '&curr_nls_comp';

