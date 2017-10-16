--
-- generate commands to kill session connected as specified user on local instance
--
set pages 500
set lines 300
set verify off


accept USERNAME prompt 'generate command to kill all sessions connected as user (can include wildcard): '
accept SID      prompt 'generate command to kill this sid: '

set termout off
column currinst new_value currinst
select sys_context('USERENV', 'INSTANCE') as currinst from dual;

column currsid new_value currsid
select sys_context('USERENV', 'SID') as currsid FROM dual;
set termout on

column cmd format a120
select 'exec rdsadmin.rdsadmin_util.kill('''||s.sid||''','''||s.serial#||''');' as cmd
  from gv$session s
 where (('&SID' is not null and s.sid = '&SID')
        or
		('&USERNAME' is not null and s.username like UPPER('&USERNAME'))
	   )
   and s.inst_id = &currinst
   -- exclude current session from kill list
   and s.sid <> &currsid
 order by s.inst_id,s.logon_time,s.sid;
