spool 'D:\oracle\utility\sqlplus\test.log'


--
-- SQL without using bind variable
--
col s1 NEW_VALUE s1
select systimestamp as s1 from dual;

declare
  vb varchar2(10);
  vc varchar2(10);
  type rc is ref cursor;
  l_cursor rc;
begin
  for i in 1 .. 9000 loop
    open l_cursor for 'select b, c from t1 where a = '|| i; 
    fetch l_cursor into vb, vc;
    close l_cursor;
  end loop;
end;
/

select systimestamp - to_timestamp_tz('&s1') as SQL_nobind_time from dual;


--
-- SQL using bind variable
--
col s2 NEW_VALUE s2
select systimestamp as s2 from dual;

declare
  vb varchar2(10);
  vc varchar2(10);
  type rc is ref cursor;
  l_cursor rc;
begin
  for i in 1 .. 9000 loop
    open l_cursor for 'select b, c from t1 where a = :1' using i; 
    fetch l_cursor into vb, vc;
    close l_cursor;
  end loop;
end;
/

select systimestamp - to_timestamp_tz('&s2') as SQL_bind_time from dual;


--
-- PLSQL 
--
col s3 NEW_VALUE s3
select systimestamp as s3 from dual;

declare
  vb varchar2(10);
  vc varchar2(10);
begin
  for i in 1 .. 9000 loop
    p1 (i, vb, vc);
  end loop;
end;
/

select systimestamp - to_timestamp_tz('&s3') as PLSQL_time from dual;

spool off;
