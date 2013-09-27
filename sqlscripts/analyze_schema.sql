accept i_owner prompt "schema: "
accept i_percent prompt "estimate_percent (default DBMS_STATS.AUTO_SAMPLE_SIZE): "

col percent new_value percent;
select nvl('&i_percent', dbms_stats.get_param('ESTIMATE_PERCENT')) percent from dual;

begin
  DBMS_STATS.GATHER_SCHEMA_STATS ( 
     ownname => upper('&i_owner')
     ,estimate_percent => &percent
     );
end;
/