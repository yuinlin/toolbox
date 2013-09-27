
col username form a12
col osuser form a12
col machine form a12
col program form a18
col logon_time form a20
col wait_time form 99999999
col cpu_stat form a20

select s.username
       ,s.osuser
--       ,i.consistent_gets
--       ,i.physical_reads
       ,s.status
       ,s.sid
--       ,s.serial#
--       ,s.machine
       ,s.program
--       ,to_char(logon_time, 'DD/MM/YYYY HH24:MI:SS') logon_time
       ,w.seconds_in_wait wait_time
       ,P.SPID
       ,name cpu_stat
       ,value
  from v$session s, v$sess_io i, v$session_wait w, V$PROCESS P, v$statname n, v$sesstat t
 where s.sid = i.sid
   and s.sid = w.sid (+)
   and 'SQL*Net message from client' = w.event(+)
   and s.osuser is not null
   and s.username is not null
   and s.paddr=p.addr
   and n.statistic# = t.statistic#
   and n.name like '%cpu%'
   and t.SID = s.sid
 order by 6 asc, 3 desc, 4 desc
/