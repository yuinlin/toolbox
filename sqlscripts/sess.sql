--
-- copied sess_sql, but dont prompt for or display session sql statement
--
set pages 500
set lines 300
set verify off

accept USERNAME prompt'enter specific username, can include wildcard (default all): '
accept MACHINENAME prompt'enter specific machine, can include wildcard (default all): '

set termout off
column currsid new_value currsid
select sys_context('USERENV', 'SID') as currsid FROM dual;

column currinst new_value currinst
select sys_context('USERENV', 'INSTANCE') as currinst from dual;
set termout on

set feedback off
column message format a60
select 'Sessions connected to ' || upper(value)
    || ' on ' || to_char(SYSDATE, 'MM/DD/YY HH24:MI:SS')
       message
  from v$parameter
 where upper(name) = 'DB_NAME';
set feedback on

column inst_id format 9
column sid format 99999
column serial# format 99999
column spid format a6
column ospid format a6
column username format a20
column machine format a26
column status format a8
column rbs format a6
column operation format a30


select s.inst_id
       ,s.sid
       ,s.serial#
       ,p.spid
       ,s.process as ospid
       ,s.username || case when s.sid = &currsid and s.inst_id = &currinst then ' *me*' end as username
       ,s.machine
       ,s.status
       ,r.segment_name rbs
       ,round(p.pga_alloc_mem/1024) allocpga_kb
       ,nvl(s.client_info,s.program) operation
  from gv$session s, gv$process p, gv$transaction t, dba_rollback_segs r
 where s.paddr = p.addr(+)
   and s.inst_id = p.inst_id(+)
   and s.taddr = t.addr(+)
   and s.inst_id = t.inst_id(+)
   and t.xidusn = r.segment_id(+)
   and ('&USERNAME' is null or
        s.username like UPPER('&USERNAME'))
   and ('&MACHINENAME' is null or
        s.machine like UPPER('&MACHINENAME'))
 order by s.inst_id, s.logon_time, s.sid;

