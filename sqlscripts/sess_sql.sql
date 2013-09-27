-- FILE : sess_sql.sql
-- DATE : 12-DEC-97
-- BY   : C Graff
--
-- USAGE: Run the script, choose the SID, see the SQL
-- 02-DEC-1999 AL   Added select of previous SQL!!
-- 21-DEC-1999 TAY added nvl(client_info,program) to select - client_info will show
--                 the schedule_operations keys of a TA process running on the
--                 server-side; otherwise it will show the name of the running program
--                 (eg. f50run32.exe,toad.exe)
--
set pages 52
set lines 140
set verify off
select 'Sessions connected to ' || upper(value)
    || ' on ' || to_char(SYSDATE, 'MM/DD/YY HH24:MI:SS')
       message
  from v$parameter
 where upper(name) = 'DB_NAME';


column username format a20
column machine format a22
column status format a8
column operation format a40
column sid format 99999
column spid format a6
column serial# format 99999
column process format a12
column rbs format a6
select s.sid, p.spid, s.serial#, s.process, s.username, s.machine, s.status,
       r.segment_name rbs, nvl(s.client_info,s.program) operation
  from v$session s, v$process p, v$transaction t, dba_rollback_segs r
 where s.paddr = p.addr(+)
   and s.taddr = t.addr(+)
   and t.xidusn = r.segment_id(+)
 order by logon_time;

ACCEPT sid NUMBER PROMPT 'Which SID to examine? '

PROMPT Previous SQL statement for session &sid
select q.sql_text
  from v$session s, v$sqltext q
 where s.prev_hash_value = q.hash_value
   and s.prev_sql_addr = q.address
   and s.sid = &sid
 order by piece;

PROMPT Current SQL statement for session &sid
select q.sql_text
  from v$session s, v$sqltext q
 where s.sql_hash_value = q.hash_value
   and s.sql_address = q.address
   and s.sid = &sid
 order by piece;



