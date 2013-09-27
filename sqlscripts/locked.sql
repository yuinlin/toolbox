set linesize 120
col object_type format a8
col object_name format a30
col osuser format a16
col dbuser format a20
col machine format a20
col sid format 9999
col lockmode format a12
 
select o.object_type
       ,o.object_name
       ,l.os_user_name as osuser
       ,l.oracle_username as dbuser
       ,s.machine
       ,s.sid
       ,case l.locked_mode when 0 then 'none'
                           when 1 then 'null (NULL)'
                           when 2 then 'row-S (SS)'
                           when 3 then 'row-X (SX)'
			   when 4 then 'share (S)'
			   when 5 then 'S/Row-X (SSX)'
			   when 6 then 'exclusive (X)'
	 end as lockmode
   from dba_objects o
       ,v$session s
       ,v$locked_object l
 where o.object_id = l.object_id
   and s.sid = l.session_id;