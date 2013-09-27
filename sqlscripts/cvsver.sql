accept PNAME prompt "stored procedure name: "
accept PTYPE prompt "stored procedure type (default PACKAGE): "

col name form a30
col sourcecode_version form a30

select name
       ,regexp_substr(text,'v [0-9.]+') as sourcecode_version 
  from user_source 
 where name = upper('&PNAME')
   and (('&PTYPE' is null and type='PACKAGE') 
        or
        type = upper('&PTYPE')
       )
   and lower(text) like '%file id: %';

