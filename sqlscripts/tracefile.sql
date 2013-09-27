SET LINESIZE 120
COLUMN trace_file FORMAT A80

SELECT value 
  FROM v$diag_info
 WHERE name = 'Default Trace File';