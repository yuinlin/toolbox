set pages 50
set lines 260
set verify off

accept USERNAME prompt'enter specific username, can include wildcard (default all): '

column sid format 99999
column username format a20
column machine format a22
column status format a8
column rbs format a6
column operation format a40
column previd format a13
column previous_sql format a50
column currid format a13
column current_sql format a50

select s.sid
       ,s.username
       ,s.machine
       ,s.status
       ,r.segment_name rbs
       ,nvl(s.client_info,s.program) operation
       ,prevq.sql_id previd
       ,rtrim(xmlagg(XMLELEMENT(E,prevq.sql_text,',').extract('//text()') order by prevq.piece).getclobval(),',') as previous_sql
       ,currq.sql_id currid
       ,rtrim(xmlagg(XMLELEMENT(E,currq.sql_text,',').extract('//text()') order by currq.piece).getclobval(),',') as current_sql
  from v$session s, v$process p, v$transaction t, dba_rollback_segs r, v$sqltext prevq, v$sqltext currq
 where s.paddr = p.addr(+)
   and s.taddr = t.addr(+)
   and t.xidusn = r.segment_id(+)
   and s.prev_hash_value = prevq.hash_value(+)
   and s.prev_sql_addr = prevq.address(+)
   and s.sql_hash_value = currq.hash_value(+)
   and s.sql_address = currq.address(+)
   and ('&USERNAME' is null or
        s.username like UPPER('&USERNAME'))
 group by s.sid
       ,s.username
       ,s.machine
       ,s.status
       ,r.segment_name
       ,nvl(s.client_info,s.program)
       ,prevq.sql_id
       ,currq.sql_id
 order by s.username;

undef USERNAME