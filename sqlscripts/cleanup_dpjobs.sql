set pages 500
set lines 300

-- inspect jobs
COL owner_name FORMAT a10; 
COL job_name FORMAT a30 
COL state FORMAT a12
COL operation LIKE state 
COL job_mode LIKE state 
COL owner.object for a50
SELECT owner_name
       ,job_name
       ,trim(operation) as operation
       ,trim(job_mode) as job_mode
       ,state
       ,attached_sessions
  FROM dba_datapump_jobs
 WHERE job_name NOT LIKE 'BIN$%'
 ORDER BY 1,2;


-- generate drop master table statements
SELECT 'drop table '||o.owner||'."'||o.object_name||'" purge;' as droptable
  FROM dba_objects o
  JOIN dba_datapump_jobs j 
    ON (o.owner=j.owner_name AND 
        o.object_name=j.job_name)
 WHERE j.state = 'NOT RUNNING'
   AND j.attached_sessions < 1
   AND j.job_name NOT LIKE 'BIN$%'
 ORDER BY o.owner||'.'||o.object_name; 
