--
-- create/drop private database link
--
set serveroutput on size 1000000

accept ACTION     prompt'action (create/drop): '
accept LINKNAME   prompt'database link name: '
accept USER       prompt'create only- fixed user: '
accept PSWD       prompt'create only- fixed user password: '
accept CONNSTR    prompt'create only- remote db service name/connection string: '

set feedback off
set verify off
begin
  if upper('&ACTION') = 'CREATE' then   
    execute immediate 'create database link &LINKNAME connect to &USER identified by &PSWD using ''&CONNSTR''';
    dbms_output.put_line ('==========================');
    dbms_output.put_line ('created database link '||'&LINKNAME');
    dbms_output.put_line ('==========================');
  --
  elsif upper('&ACTION') = 'DROP' then
    execute immediate 'drop database link &LINKNAME';
    dbms_output.put_line ('==========================');
    dbms_output.put_line ('dropped database link '||'&LINKNAME');
    dbms_output.put_line ('==========================');
  --
  else
    dbms_output.put_line ('==========================');
    dbms_output.put_line ('&ACTION'||' is an invalid action!');
    dbms_output.put_line ('==========================');
  end if;
end;
/

set feedback on
set verify on