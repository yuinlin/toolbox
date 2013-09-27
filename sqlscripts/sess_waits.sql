set pages 52
set lines 140
set verify off
set feedback off

col sid format 99999
col status format a10
col program format a20
col event format a30
col sec_in_wt format 99999999
col bksid format 99999
col bkstatus format a10
col bkprog format a20

col current_session_sql format a120
col latest_blocking_session_sqls format a120
col blocking_session new_value bsid noprint

select ss.sid
       ,ss.status
       ,ss.program
       ,ss.event
       ,ss.seconds_in_wait sec_in_wt
       ,case when ss.blocking_session_status='VALID' 
             then ss.blocking_session end bksid
       ,case when ss.blocking_session_status='VALID' 
             then (select status from v$session where sid=ss.blocking_session) end bkstatus
       ,case when ss.blocking_session_status='VALID' 
             then (select program from v$session where sid=ss.blocking_session) end bkprog
  from v$session ss
 where state='WAITING'
 order by case when type='BACKGROUND' then 1
               else 2 end;

prompt
accept sid prompt "display waiting/blocking sqls for sid: "

select s.sql_text current_session_sql
       ,case when se.blocking_session_status='VALID' 
             then se.blocking_session end blocking_session
  from v$session se
       ,v$sql s
 where s.sql_id = se.sql_id
   and se.sid=&sid;

select rownum||'-'||s.sql_text latest_blocking_session_sqls
  from v$session se
       ,v$sql s
 where s.sql_id = se.sql_id
   and se.sid='&bsid'
union all
select rownum||'-'||sql_text latest_blocking_session_sqls
  from (select s.sql_text 
	  from v$active_session_history ash
	       ,v$sql s      
	 where s.sql_id = ash.sql_id
	   and ash.session_id='&bsid'
	 order by ash.sample_time desc)
 where rownum < 6;

set feedback on
undefine bsid

