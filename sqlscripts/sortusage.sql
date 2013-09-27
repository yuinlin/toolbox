col username format a12
col sid format 999999
col tablespace format a18

SELECT s.username, s.sid, u.TABLESPACE, u.CONTENTS, u.extents, u.blocks
  FROM v$session s, v$sort_usage u
 WHERE s.saddr = u.session_addr;