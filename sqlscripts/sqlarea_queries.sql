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

	
-- looking at sql in shared sql area with info on all its child cursors (v$sql)
select sa.sql_id 
       ,sa.first_load_time
       ,sa.last_load_time
       ,sa.last_active_time
       ,sa.module
       ,sa.plan_hash_value       
       ,sa.full_plan_hash_value
	   -- from each child cursor
       ,s.child_number   
	   ,s.parsing_schema_name
       ,s.plan_hash_value as child_plan_hash_value	   
       ,s.loads
       ,s.fetches
       ,s.executions
       ,s.optimizer_cost
       ,s.disk_reads
       ,s.physical_read_bytes
       ,s.buffer_gets
       ,s.sorts
       ,s.user_io_wait_time
       ,s.elapsed_time
       ,s.last_active_time as child_last_active_time
       ,s.sql_fulltext
  from v$sqlarea sa
  join v$sql s
    on (s.sql_id = sa.sql_id and
        s.hash_value = sa.hash_value and
        s.address = sa.address)
  where lower(s.sql_fulltext) like '%timeseriesreading%'
    and s.module='w3wp.exe'
  order by sa.sql_id
           ,sa.last_active_time desc;  	

-- looking at parsed plan for each cursor of some sql(s)
select p.sql_id
       ,p.plan_hash_value
       ,p.full_plan_hash_value
       ,p.child_number
       ,p.operation
       ,p.options
       ,p.object_owner
       ,p.object_name
       ,p.object_alias
       ,p.object_type
       ,p.optimizer
       ,p.cost
       ,p.bytes
       ,p.cpu_cost
       ,p.io_cost
       ,p.cardinality
       ,p.access_predicates
       ,p.filter_predicates
from v$sql s
  join v$sql_plan p
    on (p.sql_id = s.sql_id and
        p.child_number = s.child_number)
  where (lower(s.sql_fulltext) like '%timeseriesreading%' or
         lower(s.sql_fulltext) like '%timeseriesdischargereading%')
    and s.module='w3wp.exe'
  order by s.sql_id
           ,p.plan_hash_value  
           ,p.child_number
           ,p.depth;           

--
-- generating bind variable settings from dba_hist_sqlbind
-- !remove quotes from non char variables!
--
select 'var '||replace(name,':','v')||' '||datatype_string||chr(10)||'exec :'||replace(name,':','v')||' :='''||value_string||''''
from dba_hist_sqlbind where sql_id = 'df9ag3dxgtk6b' and to_char(last_captured,'yyyy-mm-dd hh24:mi')='2017-11-01 14:49'
order by snap_id, name;
		   