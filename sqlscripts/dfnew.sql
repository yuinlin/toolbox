REM File: df.sql
REM This file is distributed free of change and no warranty
REM of any kind is stated or implied
REM YL: added display of tempfiles

col global_name new_value xinstance
set termout off
select substr (global_name,1,instr(global_name,'.')-1) global_name
from global_name;
set termout on

ttitle center &&xinstance. " data files" skip 2
col TodaysDate format a20
column "TYPE" format a4
column "NAME" format a75
column "TB SP" format a20
column "ID" format 999
column "MBYTES" format 9999999.99
column "AUTOEXT" format a6
break on "TB SP" skip 1
compute sum of "MBYTES" on "TB SP"
compute sum of "MBYTES" on report
set feedback off
set echo off
set pagesize 2000

--spool c:\local\df.lis

select ftype "TYPE", file_id "ID",file_name "NAME",
       tablespace_name "TB SP", bytes/(1024*1024) "MBYTES", autoextensible "AUTOEXT"
  from (select 'data' as ftype, d.file_id, d.file_name, d.tablespace_name, d.bytes, d.autoextensible from sys.dba_data_files d union all
        select 'temp' as ftype, t.file_id, t.file_name, t.tablespace_name, t.bytes, t.autoextensible from sys.dba_temp_files t)
 order by tablespace_name, file_id
/

ttitle off

select
to_char(sysdate,'dd-Mon-yyyy hh24:mi:ss') "TodaysDate"
from
sys.dual
/

--spool off
set pagesize 24
set feedback on
