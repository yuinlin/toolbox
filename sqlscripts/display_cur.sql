set linesize 200
set pagesize 0

accept SQLSTRING prompt 'display cursor for sql containting string: '
accept FORMAT prompt 'display for format (basic,typical,serial,all,adaptive) default [typical]: '

set verify off

select t.*
  from v$sql s,
       table(DBMS_XPLAN.DISPLAY_CURSOR(s.sql_id, s.child_number, upper(nvl('&FORMAT','TYPICAL')))) t
 WHERE lower(s.sql_text) LIKE lower('%&SQLSTRING%');

set verify on
