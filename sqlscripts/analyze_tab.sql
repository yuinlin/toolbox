accept i_owner prompt "ownname (default current user): "
accept tab prompt "tabname: "
accept i_percent prompt "estimate_percent (default DBMS_STATS.AUTO_SAMPLE_SIZE): "

col owner new_value owner;
select nvl('&i_owner',user) owner from dual;

col percent new_value percent;
select nvl('&i_percent', dbms_stats.get_param('ESTIMATE_PERCENT')) percent from dual;

begin
  DBMS_STATS.GATHER_TABLE_STATS ( 
     ownname => upper('&owner')
     ,tabname => upper('&tab')
     ,estimate_percent => &percent
     );
end;
/