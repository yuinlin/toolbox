accept SCHEMA prompt "do schema (default all non-system schemas): "
accept INVAL_ONLY prompt "do only invalidated objects? (y/n, default y): "
accept REUSE_SETTINGS prompt "reuse settings? (y/n, default y): "
accept DEBUG prompt "debug mode? (y/n, default n): "

spool compile_all_cc.log

select to_char(sysdate, 'MM/DD/YYYY HH24:MI:SS') from dual;


-- display conditional compilation directives
col name form a30
col value form a80
select name, value from v$parameter where lower(name) like 'plsql_cc%';


-- compile
set verify off
set serveroutput on size 100000
declare
   keep_trying boolean := true;
   max_tries number := 6;
   try_count number := 0;  
   v_invalid_count number;
begin
   -- go through compilation for ALL objects once if specified
   FOR r IN (select 'alter ' || replace(o.object_type, ' BODY') || ' ' || o.owner || '.' || o.object_name ||
                     decode(o.object_type, 'PACKAGE BODY', ' compile body', ' compile') ||
                     decode(upper(nvl('&REUSE_SETTINGS','Y')),'Y',' reuse settings')
                     as compile_statement
               from dba_objects o
               left join dba_dependencies d
                 on (d.referenced_name = o.object_name and
                     d.referenced_type = o.object_type and
                     d.referenced_owner = o.owner
                    )
              where o.object_type in ('PROCEDURE','PACKAGE','FUNCTION','TRIGGER','VIEW','MATERIALIZED VIEW','PACKAGE BODY')
                and UPPER('&INVAL_ONLY') = 'N'
                and ( ('&SCHEMA' is null and o.owner in (select t.owner from dba_tables t where t.table_name='SCHEMA_MAP'))
                       or
                      (o.owner = upper('&SCHEMA'))
                    )  
              group by o.owner, o.object_type, o.object_name
              order by count(*)
            )
   LOOP
     BEGIN
         IF nvl(upper('&DEBUG'),'N') = 'Y' THEN
            dbms_output.put_line('ALL, doing: '||r.compile_statement);
         END IF;
         execute immediate r.compile_statement;
     EXCEPTION 
        WHEN no_data_found THEN EXIT;
        WHEN others THEN NULL;
      END;
   END LOOP;
   -- go through compiliation for all INVALID objects for as many as max tries
   WHILE keep_trying LOOP
      -- 
      FOR r IN (select 'alter ' || replace(o.object_type, ' BODY') || ' ' || o.owner || '.' || o.object_name || 
                       decode(o.object_type, 'PACKAGE BODY', ' compile body', ' compile') ||
                       decode(upper(nvl('&REUSE_SETTINGS','Y')),'Y',' reuse settings')
                       as compile_statement
                  from dba_objects o
                 where o.object_type in ('PROCEDURE','PACKAGE','FUNCTION','TRIGGER','VIEW','MATERIALIZED VIEW','PACKAGE BODY')
                   and o.status = 'INVALID'
                   and ( ('&SCHEMA' is null and o.owner in (select t.owner from dba_tables t where t.table_name='SCHEMA_MAP'))
                         or
                         (o.owner = upper('&SCHEMA'))
                       )  
                 order by o.owner, decode(o.object_type, 'PACKAGE BODY', 1, 2), o.object_type)
      LOOP
         BEGIN
            IF nvl(upper('&DEBUG'),'N') = 'Y' THEN
               dbms_output.put_line('INVAL, doing: '||r.compile_statement);
            END IF;
            execute immediate r.compile_statement;
         EXCEPTION 
            WHEN no_data_found THEN EXIT;
            WHEN others THEN NULL;
         END;
      END LOOP;
      --
      try_count := try_count + 1;
      dbms_output.put_line('done '||try_count||' loop');
      begin
         select count(*) 
           into v_invalid_count 
           from dba_objects o
          where o.status = 'INVALID'
            and o.object_type in ('PROCEDURE','PACKAGE','FUNCTION','TRIGGER','VIEW','MATERIALIZED VIEW','PACKAGE BODY')
            and ( ('&SCHEMA' is null and o.owner in (select t.owner from dba_tables t where t.table_name='SCHEMA_MAP'))
                  or
                  (o.owner = upper('&SCHEMA'))
                );
      exception when others then v_invalid_count := 1;
      end;
      IF v_invalid_count = 0 or try_count > max_tries THEN
         keep_trying := false;
      END IF;  
   END LOOP;
end;
/


set verify on

select to_char(sysdate, 'MM/DD/YYYY HH24:MI:SS') from dual;

spool off

--disconn