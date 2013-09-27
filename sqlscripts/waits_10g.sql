set verify off

accept USERNAME prompt'enter specific username, can include wildcard (default all): '
accept WAITTIME prompt'enter wait time threshold (default no threshold): '

set verify on
col wait_class form a20
--10g
select s.inst_id
       ,s.sid
       ,s.serial#
       ,p.spid
       ,s.status
       ,s.username
       ,s.wait_class
       ,s.seconds_in_wait as wait_sec
  from gv$session s, gv$process p
 where s.paddr = p.addr(+)
   and s.inst_id = p.inst_id(+)
   -- check for specified user connections that's currently waiting for something for over the specified minutes
   and ('&USERNAME' is null or s.username like upper('&USERNAME'))
   and s.wait_time = 0
   and s.seconds_in_wait >= NVL('&WAITTIME', 0);
