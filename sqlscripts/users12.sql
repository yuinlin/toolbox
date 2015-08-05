col username form a30

select (select c.name from v$containers c where c.con_id = u.con_id) as container
       ,u.username
  from cdb_users u 
 order by u.con_id, u.username;