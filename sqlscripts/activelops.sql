col sid format 9999
col opname format a20
col sql_id format a13
col time_remaining format 99999999999
col start_time format a21
col totalwork format 99999999999
col sofar format 99999999999


select sid
       ,opname
       ,sql_id
       ,time_remaining
       ,to_char(start_time,'mm/dd/rrrr hh24:mi:ss') as start_time
       ,totalwork, sofar 
  from v$session_longops
 where totalwork != sofar
 order by sid
          ,start_time;

accept sqlid prompt 'find sql for sql_id: '

set verify off
col sql_text format a100

select sql_text
  from v$sql
 where sql_id = trim('&sqlid');


set verify on