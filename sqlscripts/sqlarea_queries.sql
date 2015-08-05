-- looking at captured sql bind values
select s.sql_id
       ,s.parsing_schema_name
       ,s.sql_fulltext         -- text of a query
       ,bc.was_captured        -- was the bind value captured
       ,bc.last_captured
       ,bc.name                -- name of a bind variable
       ,bc.value_string        -- value of a bind variable
       ,case when bc.datatype_string = 'TIMESTAMP' 
             then anydata.accesstimestamp(bc.value_anydata) 
             end as value_timestamp
       ,bc.precision
       ,bc.scale
  from v$sqlarea s
  join v$sql_bind_capture bc
    on (bc.sql_id = s.sql_id)
  where s.parsing_schema_name = 'YUIN2'
    and s.sql_fulltext like 'WITH token_expired as%';

-- find address and hash value of sql to purge
select distinct s.parsing_schema_name, 'exec DBMS_SHARED_POOL.PURGE (''' || s.address ||','|| s.hash_value || ''', ''C'');'
  from v$sqlarea s
  where s.sql_fulltext like 'WITH token_expired as%';

-- looking at parsed sql execution plans
select p.*
  from v$sqlarea s
  join v$sql_plan p
    on (p.sql_id = s.sql_id and
        p.address = s.address and
        p.hash_value = s.hash_value)
  where s.sql_fulltext like 'WITH token_expired as%'
    and p.object_name = 'PK_TEL';