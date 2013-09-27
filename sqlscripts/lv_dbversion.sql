accept schema prompt 'display version numbers for schema (default all): '
accept releasename prompt 'display version numbers for release name like: '

set serveroutput on size 1000000

declare
  type string_tabtype is table of varchar2(3000) index by pls_integer;
  sql_tab string_tabtype;
  result_tab string_tabtype;
  rcur sys_refcursor;
begin
  --
  -- generate ref cur SQL statements
  select 'select rpad('''||owner||''',20)
         ||rpad(d.version_number||(select ''-ROLLEDBACK'' from '||owner
         ||'.database_version d2 where d2.description like ''Rollback%'' and rtrim(d2.version_number,''R'') = d.version_number and d2.updated_date > d.updated_date),34)
         ||rpad(substr(d.description,1,50),52)||rpad(to_char(d.updated_date,''MM/DD/YY HH24:MI:SS''),20) from '||owner
         ||'.database_version d where lower(d.description) like lower(''&releasename%'') order by d.updated_date,d.version_number'
    bulk collect into sql_tab
    from dba_tables
   where table_name='SCHEMA_MAP'
     and ( ('&schema' IS NOT NULL and owner = UPPER('&schema'))
           or
           ('&schema' IS NULL)
         );
  --
  -- open ref cursor for each generated SQL
  for i in sql_tab.FIRST .. sql_tab.LAST loop
    -- a header per ref cur
    dbms_output.put_line('=====================');
    -- fetch results from ref cur
    open rcur for sql_tab(i);
    fetch rcur bulk collect into result_tab;
    close rcur;
    -- display results
    for i in result_tab.FIRST .. result_tab.LAST loop
      dbms_output.put_line(result_tab(i));
    end loop;
  end loop;
  --
exception when others then
  close rcur;
end;
/
