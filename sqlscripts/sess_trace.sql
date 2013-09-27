--
-- show session(s) trace info, and enable/disable tracing on specified session
--
set pages 500
set lines 300
set verify off

--
-- show session(s) info
accept USERNAME prompt'enter specific username, can include wildcard (default all): '

set termout off
column currsid new_value currsid
select sys_context('USERENV', 'SID') as currsid FROM dual;

column currinst new_value currinst
select sys_context('USERENV', 'INSTANCE') as currinst from dual;
set termout on

set feedback off
column message format a60
select 'Sessions connected to ' || upper(value)
    || ' at ' || to_char(SYSDATE, 'MM/DD/YY HH24:MI:SS')
       message
  from v$parameter
 where upper(name) = 'DB_NAME';
set feedback on

column inst_id format 9
column sid format 99999
column serial# format 99999
column ospid format a6
column username format a20
column status format a8
column trace format a8
column waits format a5
column binds format a5
column client_id format a20
column service format a16
column module format a24
column action format a20

select s.inst_id
       ,s.sid
       ,s.serial#
       ,p.spid as ospid
       ,s.username || case when s.sid = &currsid and s.inst_id = &currinst then ' *me*' end as username
       ,s.status
       ,s.sql_trace as trace
       ,s.sql_trace_waits as waits
       ,s.sql_trace_binds as binds
       ,s.client_identifier as client_id
       ,s.service_name as service
       ,s.module
       ,s.action
  from gv$session s, gv$process p, gv$transaction t
 where s.paddr = p.addr(+)
   and s.inst_id = p.inst_id(+)
   and s.taddr = t.addr(+)
   and s.inst_id = t.inst_id(+)
   and ('&USERNAME' is null or
        s.username like UPPER('&USERNAME'))
 order by s.inst_id, logon_time;

--
-- enable/disable a SQL trace
ACCEPT en_sid PROMPT 'Enable SQL trace on local instance for session SID: '
ACCEPT en_serial PROMPT 'Enable SQL trace on local instance for session SERIAL: '
ACCEPT dis_sid PROMPT 'Disable SQL trace on local instance for session SID: '
ACCEPT dis_serial PROMPT 'Disable SQL trace on local instance for session SERIAL: '

set serveroutput on size 100000
BEGIN
  IF '&en_sid' IS NOT NULL AND '&en_serial' IS NOT NULL THEN
    DBMS_MONITOR.session_trace_enable(session_id => to_number('&en_sid'), serial_num => to_number('&en_serial'), binds=>true);
    dbms_output.put_line('== ');
    dbms_output.put_line('== enabled trace for SID &en_sid SERIAL &en_serial');
  END IF;
  --
  IF '&dis_sid' IS NOT NULL AND '&dis_serial' IS NOT NULL THEN
    DBMS_MONITOR.session_trace_disable(session_id => to_number('&dis_sid'), serial_num => to_number('&dis_serial'));
    dbms_output.put_line('== ');
    dbms_output.put_line('== disabled trace for SID &dis_sid SERIAL &dis_serial');
  END IF;
END;
/
