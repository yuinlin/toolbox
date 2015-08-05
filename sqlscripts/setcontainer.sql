accept NEWCONNAME prompt "set session container to: "

alter session set container=&NEWCONNAME;

-- show con_name (i have problem with this show command on windows client, so use sys_context instead)
col "current container" form a30
col "current container ID" form a10
select sys_context('USERENV','CON_NAME') as "current container"
       ,sys_context('USERENV','CON_ID') as "current container ID"
  from dual;

undef NEWCONNAME