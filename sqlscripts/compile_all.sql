spool compile_all.log

select to_char(sysdate, 'MM/DD/YYYY HH24:MI:SS') from dual;

set serveroutput on size 100000
begin
   FOR i IN 1..6 LOOP
      FOR r IN (select 'alter ' || replace(object_type, ' BODY') || ' ' || object_name || 
                       decode(object_type, 'PACKAGE BODY', ' compile body', ' compile') 
                       as compile_statement
                  from user_objects
                 where object_type in ('PROCEDURE','PACKAGE','FUNCTION',
                                       'TRIGGER','VIEW','MATERIALIZED VIEW','PACKAGE BODY')
                   and status = 'INVALID'
                 order by decode(object_type, 'PACKAGE BODY', 1, 2), object_type)
      LOOP
         BEGIN
            execute immediate r.compile_statement;
         EXCEPTION 
            WHEN no_data_found THEN EXIT;
            WHEN others THEN NULL;
         END;
      END LOOP;
   END LOOP;
end;
/

select to_char(sysdate, 'MM/DD/YYYY HH24:MI:SS') from dual;

spool off
--exit
