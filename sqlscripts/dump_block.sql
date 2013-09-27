accept vrowid prompt "enter rowid: "

begin
  execute immediate 
    'alter system dump datafile ' || 
    dbms_rowid.rowid_relative_fno('&vrowid') ||
    ' block ' ||
    dbms_rowid.rowid_block_number('&vrowid');
end;
/

select u_dump.value || '\' || i.value || '_ora_' || v$process.spid || '.trc'
  from v$parameter u_dump 
 cross join v$parameter i
 cross join v$process 
       join v$session 
    on v$process.addr = v$session.paddr
 where u_dump.name  = 'user_dump_dest'
   and i.name = 'instance_name'
   and v$session.audsid=sys_context('userenv','sessionid');

