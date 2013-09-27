set pages 52
set lines 140
set verify off

column sid format 99999
column event format a30
column total_waits format 999999999999
column time_waited format 999999999999
column seconds_in_wait format 999999999999
column state format a20

accept sid prompt "display cumulative wait events for SID: "

select sid, event, total_waits "TTL WAITS (cs)", time_waited "TIME WAITED (cs)", seconds_in_wait, state 
  from (select 'a' as flag, sid, event, null as total_waits, wait_time as time_waited, seconds_in_wait, state
          from v$session_wait
         union all
        select 'b' as flag, sid, event, total_waits, time_waited, null as seconds_in_await, 'DONE' as state
          from v$session_event)
 where sid = &sid
 order by sid, flag;