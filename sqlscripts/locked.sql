accept USERNAME prompt'enter specific username, can include wildcard (default all): '

set linesize 240
col sid format 99999
col holder format a30
col lt format a2
col lockmode format a14
col block format 9
col object_owner format a30
col object_name format a30
col object_locked_mode format a14
 
select l.sid
       ,s.username as holder
       ,l.type lt
       ,case l.lmode when 0 then 'None' 
                     when 1 then 'Null'
                     when 2 then 'Row-S (SS)'
                     when 3 then 'Row-X (SX)'
                     when 4 then 'Share'
                     when 5 then 'S/Row-X (SSX)'
                     when 6 then 'Exclusive'
                     else to_char(l.lmode) end as lockmode                     
       ,l.block
       ,d.owner as object_owner
       ,d.object_name
       ,case o.locked_mode when 0 then 'None' 
                     when 1 then 'Null'
                     when 2 then 'Row-S (SS)'
                     when 3 then 'Row-X (SX)'
                     when 4 then 'Share'
                     when 5 then 'S/Row-X (SSX)'
                     when 6 then 'Exclusive'
                     else to_char(o.locked_mode) end as object_locked_mode
  from v$lock l
       ,v$locked_object o
       ,dba_objects d
       ,v$session s
 where l.sid = s.sid
   and ('&USERNAME' is null or
        s.username like UPPER('&USERNAME'))
   and l.type in ('TM','TX','UL')
   and o.object_id(+) = l.id1
   and (o.session_id = s.sid or o.object_id is null)
   and d.object_id(+) = o.object_id
 order by l.sid
          ,o.xidsqn;
