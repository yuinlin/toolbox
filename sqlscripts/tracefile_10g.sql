SET LINESIZE 120
COLUMN trace_file FORMAT A80

SELECT s.sid,
       s.serial#,
       pa.value || 
       (select case when dbms_utility.port_string like '%WIN%' then '\' else '/' end from dual)  -- os specific slash
       || LOWER(SYS_CONTEXT('userenv','instance_name')) 
       || '_ora_' || p.spid || '.trc' AS trace_file
FROM   v$session s,
       v$process p,
       v$parameter pa
WHERE  pa.name = 'user_dump_dest'
AND    s.paddr = p.addr
AND    s.audsid = SYS_CONTEXT('USERENV', 'SESSIONID');