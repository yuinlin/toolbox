set linesize 200
set pagesize 0

accept FORMAT prompt 'display for format (basic,typical,serial,all) default [typical]: '

set verify off
select * from table(dbms_xplan.display(format=>upper(nvl('&FORMAT','TYPICAL'))));

set verify on

