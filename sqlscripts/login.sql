REM dont printout anything when logging in
set termout off

REM barbaz foo

REM set textpad as sql*Plus default editor
define _editor=vi

REM set serveroutput on to max size, and wrapped to preserve leading whitespace
set serveroutput on size 1000000 format wrapped

REM set linesize
set linesize 200

REM show user and db in prompt
set sqlprompt "_user'@'_connect_identifier _date> "

REM alter session set nls_date_format = 'mm/dd/rr hh24:mi';
alter session set nls_date_format = 'mm/dd/rr hh24:mi';

REM re-enable print to screen
set termout on
