accept i_owner prompt "ownname (default current user): "

col owner new_value owner;
select nvl('&i_owner',user) owner from dual;

begin
  for i in (select owner, table_name from all_tables where owner = upper('&owner') and nvl(trunc(last_analyzed),sysdate+1) <> trunc(sysdate))
  loop
    begin
      DBMS_STATS.GATHER_TABLE_STATS (ownname => i.owner
                                     ,tabname => i.table_name);
    exception when others then null;
    end;
  end loop;
end;
/