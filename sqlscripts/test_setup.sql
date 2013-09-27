drop table t1;
create table t1 (a number(10), b varchar2(10), c varchar2(10));

insert into t1 (a, b, c) select rownum, 'a','b' from all_objects;
commit;


create or replace procedure p1 
  (i_a in number, o_b out nocopy varchar2, o_c out nocopy varchar2)
as
begin
  select b, c into o_b, o_c from t1 where a = i_a;
end p1;
/


