-- as admin

drop table common_objects;
create global temporary table common_objects (object_type varchar2(30) not null, name varchar2(30) not null) on commit preserve rows;

drop table diff_result;
create global temporary table diff_result (object_type varchar2(30) not null, name varchar2(30) not null, message varchar2(4000), diff clob) on commit preserve rows;


create or replace package schema_diff
authid current_user
as
  b_save_result boolean;
  
  c_type_table constant varchar2(30) := 'TABLE';
  c_type_view constant varchar2(30) := 'VIEW';
  c_type_mview constant varchar2(30) := 'MATERIALIZED_VIEW';
  c_type_mview_log constant varchar2(30) := 'MATERIALIZED_VIEW_LOG';  
  c_type_index constant varchar2(30) := 'INDEX';
  c_type_trigger constant varchar2(30) := 'TRIGGER';
  c_type_synonym constant varchar2(30) := 'SYNONYM';
  c_type_sequence constant varchar2(30) := 'SEQUENCE';
  c_type_package dba_procedures.object_type%type := 'PACKAGE';
  c_type_procedure dba_procedures.object_type%type := 'PROCEDURE';
  c_type_function dba_procedures.object_type%type := 'FUNCTION';  
  c_type_type dba_procedures.object_type%type := 'TYPE';
    
  procedure compare (i_schema1 in varchar2, i_schema2 in varchar2, i_save_result in number);
end;
/

create or replace package body schema_diff
as
  ---------------------------------------------------------------------
  -- private
  ---------------------------------------------------------------------
  procedure write_missing
    (i_type in varchar2, i_name in varchar2, i_schema in varchar2) 
  is
  begin
    dbms_output.put_line('-- '||lower(i_type)||' '||i_name||' is missing from schema '||i_schema);
    
    if b_save_result
    then
      insert into admin.diff_result(object_type, name, message) values (i_type, i_name, 'is missing from schema '||i_schema);
    end if;        
  end write_missing;
  
  procedure write_diff
    (i_type in varchar2, i_name in varchar2, i_msg1 in clob, i_msg2 in clob, i_msg3 in clob default null) 
  is
  begin
    dbms_output.put_line('-- '||lower(i_type)||' '||i_name||' is different between schemas');        
    
    if (i_msg1 is not null)
    then
      dbms_output.put(i_msg1);
      dbms_output.put_line('');
      dbms_output.put_line('');
    end if;
    
    if (i_msg2 is not null)
    then
      dbms_output.put(i_msg2);
      dbms_output.put_line('');
      dbms_output.put_line('');
    end if;

    if (i_msg3 is not null)
    then
      dbms_output.put(i_msg3);
      dbms_output.put_line('');
      dbms_output.put_line('');
    end if;
    
    if b_save_result
    then
      insert into admin.diff_result(object_type, name, message, diff)
      values (i_type, i_name, ' is different between schemas', trim(both chr(10) from i_msg1||chr(10)||i_msg2||chr(10)||i_msg3));
    end if;        
  end write_diff;

  procedure verify_schemas
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_count pls_integer := 0;
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    select count(*) into v_count
      from dba_users
     where username in (v_schema1, v_schema2);
    
    if v_count != 2 then
      raise_application_error (-20101, 'input schemas must exist!');
    end if;
  end verify_schemas;
  
  procedure missing_tables
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    for i in (select table_name
                from dba_tables 
               where owner=v_schema1
                 and table_name not in ('SCHEMA_UPGRADE_PARAM')
                 and (iot_type is null or iot_type = 'IOT') 
              minus 
              select table_name
                from dba_tables 
               where owner=v_schema2             
                 and table_name not in ('SCHEMA_UPGRADE_PARAM')
                 and (iot_type is null or iot_type = 'IOT') 
             )
    loop
      write_missing(c_type_table, i.table_name, v_schema2);
    end loop;
  end missing_tables;
 
  procedure get_common_tables
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    delete admin.common_objects where object_type=c_type_table;
    insert into admin.common_objects (name, object_type)
    select table_name
           ,c_type_table
      from (select table_name
              from dba_tables 
             where owner=v_schema1
               and table_name not in ('SCHEMA_UPGRADE_PARAM')
               and (iot_type is null or iot_type = 'IOT')
            intersect
            select table_name
              from dba_tables 
             where owner=v_schema2
               and table_name not in ('SCHEMA_UPGRADE_PARAM')
               and (iot_type is null or iot_type = 'IOT')
           );
  end get_common_tables;

  function get_ddl
    (i_schema in varchar2, i_object_name in varchar2, i_object_type in varchar2)
  return clob 
  is
    h number;
    th number;   
    ddl clob;
    v_schema varchar2(30) := upper(i_schema); 
    v_object_name varchar2(30) := upper(i_object_name); 
    v_object_type varchar2(30) := upper(i_object_type); 
  begin
    -- specify the object type and filters 
    h := dbms_metadata.open(v_object_type);
    dbms_metadata.set_filter(h,'SCHEMA', v_schema);
    dbms_metadata.set_filter(h,'NAME', v_object_name);

    -- remap schema so result can be be compared
    th := dbms_metadata.add_transform(h,'MODIFY');
    dbms_metadata.set_remap_param(th,'REMAP_SCHEMA',v_schema,'TEMPSCHEMA');

    -- transform to ddl
    th := dbms_metadata.add_transform(h,'DDL'); 

    -- fetch and close
    ddl := dbms_metadata.fetch_clob(h);
    dbms_metadata.close(h);
    
    return ddl;
  end get_ddl; 

  function get_schema_remapped_sxml
    (i_schema in varchar2, i_object_name in varchar2, i_object_type in varchar2)
  return clob 
  is
    h number;
    th number;   
    sxml clob;
    v_schema varchar2(30) := upper(i_schema); 
    v_object_name varchar2(30) := upper(i_object_name); 
    v_object_type varchar2(30) := upper(i_object_type); 
  begin
    -- specify the object type and filtering
    h := dbms_metadata.open(v_object_type);
    dbms_metadata.set_filter(h,'SCHEMA', v_schema);
    dbms_metadata.set_filter(h,'NAME', v_object_name);

    -- remap schema so dependent objects like constraints can be compared
    th := dbms_metadata.add_transform(h,'MODIFY');
    dbms_metadata.set_remap_param(th,'REMAP_SCHEMA',v_schema,'TEMPSCHEMA');

    -- transform to sxml, removing storage and tablespace info
    th := dbms_metadata.add_transform(h,'SXML'); 
    dbms_metadata.set_transform_param(th,'STORAGE',false);
    dbms_metadata.set_transform_param(th,'TABLESPACE',false);

    -- fetch and close
    sxml := dbms_metadata.fetch_clob(h);
    dbms_metadata.close(h);

    return sxml;
  end get_schema_remapped_sxml;
  
  function get_diff_sxml
    (i_schema1 in varchar2, i_schema2 in varchar2, i_object_name in varchar2, i_object_type in varchar2) 
  return clob is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
    v_object_name varchar2(30) := upper(i_object_name); 
    v_object_type varchar2(30) := upper(i_object_type); 
    doc1 clob;
    doc2 clob;
    diffdoc clob;
    openc_handle number;
    openw_handle number;
    openw_handle2 number;
    transform_handle number;
    transform_handle2 number;
    alterxml clob; 
    alterddl clob; 
  begin
    -- fetch sxml for the objects
    doc1 := replace(get_schema_remapped_sxml(v_schema1, v_object_name, v_object_type),chr(10));
    doc2 := replace(get_schema_remapped_sxml(v_schema2, v_object_name, v_object_type),chr(10));

    -- openc handle for object type
    openc_handle := DBMS_METADATA_DIFF.OPENC(v_object_type);

    -- add the 2 docs to compare
    dbms_metadata_diff.add_document(openc_handle,doc1);
    dbms_metadata_diff.add_document(openc_handle,doc2);

    -- fetch the sxml difference document
    diffdoc := dbms_metadata_diff.fetch_clob(openc_handle);
    dbms_metadata_diff.close(openc_handle);
    
    return diffdoc;
  end get_diff_sxml;
  
  function to_alterddl
    (i_diffsxml in clob, i_object_type in varchar2) 
  return clob is
    v_object_type varchar2(30) := upper(i_object_type); 
    openw_handle number;
    openw_handle2 number;
    transform_handle number;
    transform_handle2 number;
    alterxml clob; 
    alterddl clob; 
  begin
    -- transform the sxml diff to alter xml 
    openw_handle := dbms_metadata.openw(v_object_type);
    transform_handle := dbms_metadata.add_transform(openw_handle,'ALTERXML');
    dbms_lob.createtemporary(alterxml, true);
    dbms_metadata.convert(openw_handle,i_diffsxml,alterxml);
    dbms_metadata.close(openw_handle);

    -- transform the alter xml to alter ddl
    openw_handle2 := dbms_metadata.openw(v_object_type);
    transform_handle2 := dbms_metadata.add_transform(openw_handle2,'ALTERDDL');
    dbms_metadata.set_transform_param(transform_handle2,'SQLTERMINATOR',true);
    dbms_lob.createtemporary(alterddl, TRUE );
    dbms_metadata.convert(openw_handle2,alterxml,alterddl);
    dbms_metadata.close(openw_handle2);

    return alterddl; 
  end to_alterddl;
  
  function chrlength_semantic_check
    (i_schema1 in varchar2, i_schema2 in varchar2, i_table_name in varchar2) 
  return clob is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
    v_table_name varchar2(30) := upper(i_table_name); 
    diff clob;
  begin
    for i in (  with common_columns as
                     (select table_name, column_name
                        from dba_tab_columns
                       where owner=v_schema1
                         and table_name=v_table_name
                      intersect   
                      select table_name, column_name
                        from dba_tab_columns
                       where owner=v_schema2
                         and table_name=v_table_name                    
                     )
              select d.column_name, char_used
                from dba_tab_columns d
                join common_columns c
                  on (d.table_name = c.table_name and
                      d.column_name = c.column_name)
               where owner=v_schema1
               minus
              select d.column_name, char_used
                from dba_tab_columns d
                join common_columns c
                  on (d.table_name = c.table_name and
                      d.column_name = c.column_name)              
               where owner=v_schema2
             )
    loop
      diff := diff ||chr(10)||'column '||i.column_name||' has different character length semantics';
    end loop;
    return diff;
  end chrlength_semantic_check;

  function table_attributes_check
    (i_schema1 in varchar2, i_schema2 in varchar2, i_table_name in varchar2) 
  return clob is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
    v_table_name varchar2(30) := upper(i_table_name); 
    diff clob;
  begin
    for i in (select d.table_name, read_only
                from dba_tables d
               where d.table_name=v_table_name
		 and d.owner=v_schema1
               minus
              select d.table_name, read_only
                from dba_tables d
               where d.table_name=v_table_name
		 and d.owner=v_schema2
             )
    loop
      diff := diff ||chr(10)||'table '||i.table_name||' has different read/write mode';
    end loop;
    return diff;
  end table_attributes_check;
  
  procedure allocate_extent
    (i_schema in varchar2, i_table_name in varchar2) 
  is
    v_schema varchar2(30) := upper(i_schema); 
    v_table_name varchar2(30) := upper(i_table_name); 
  begin
    for i in (select table_name
                from dba_tables
               where owner=v_schema
                 and table_name = v_table_name
                 and tablespace_name is not null
               minus
              select segment_name
                from dba_segments
               where owner=v_schema
                 and segment_name = v_table_name
             )
    loop           
      dbms_output.put_line('INFO: alter table '||v_schema||'.'||v_table_name||' allocate extent');  
      execute immediate 'alter table '||v_schema||'.'||v_table_name||' allocate extent';
    end loop;  
  end allocate_extent;

  procedure diff_tables
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    for i in (select name from admin.common_objects where object_type = c_type_table)
    loop
      allocate_extent(v_schema1,i.name);
      allocate_extent(v_schema2,i.name);
      declare
        chrlength_diff clob;
	attribute_diff clob;
        diffsxml clob;
        alterddl clob;
      begin
        diffsxml := get_diff_sxml(v_schema1,v_schema2,i.name,c_type_table);
        
        if (instr(diffsxml,'src="') != 0 or
            instr(diffsxml,'value1="') != 0)      
        then
          chrlength_diff := chrlength_semantic_check(v_schema1,v_schema2,i.name);
        end if;      

	attribute_diff := table_attributes_check(v_schema1, v_schema2,i.name);

        alterddl := to_alterddl(diffsxml,c_type_table);
        
        if (dbms_lob.getlength(chrlength_diff) > 0 or
	    dbms_lob.getlength(alterddl) > 0 or
	    dbms_lob.getlength(attribute_diff) > 0
	   )
        then
          write_diff(c_type_table, i.name, chrlength_diff, alterddl, attribute_diff);
        end if;
      end;    
    end loop;
  end diff_tables;

  procedure missing_views
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    for i in (select view_name
                from dba_views 
               where owner=v_schema1
              minus 
              select view_name
                from dba_views
               where owner=v_schema2             
             )
    loop
      write_missing(c_type_view, i.view_name, v_schema2);
    end loop;
  end missing_views;

  procedure get_common_views
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    delete admin.common_objects where object_type=c_type_view;
    insert into admin.common_objects (name, object_type)
    select view_name
           ,c_type_view
      from (select view_name
              from dba_views
             where owner=v_schema1
            intersect
            select view_name
              from dba_views
             where owner=v_schema2
           );
  end get_common_views;

  procedure diff_object
    (i_schema1 in varchar2, i_schema2 in varchar2, i_object_type varchar2) 
  is
    v_object_type varchar2(30) := upper(i_object_type); 
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    for i in (select name from admin.common_objects where object_type = v_object_type)
    loop
      declare
        diffsxml clob;
        ddl1 clob;
        ddl2 clob;      
      begin
        diffsxml := get_diff_sxml(v_schema1,v_schema2,i.name,v_object_type);
        
        if (instr(diffsxml,'src="') != 0 or
            instr(diffsxml,'value1="') != 0)      
        then
          dbms_metadata.set_transform_param(dbms_metadata.session_transform,'STORAGE',false);
          dbms_metadata.set_transform_param(dbms_metadata.session_transform,'TABLESPACE',false);
          ddl1 := dbms_metadata.get_ddl(object_type=>v_object_type,name=>i.name,schema=>v_schema1);
          ddl2 := dbms_metadata.get_ddl(object_type=>v_object_type,name=>i.name,schema=>v_schema2);      
          dbms_metadata.set_transform_param(dbms_metadata.session_transform,'DEFAULT');
          
          write_diff(v_object_type, i.name, 'schema '||v_schema1||':'||ddl1, 'schema '||v_schema2||':'||ddl2);
        end if;
      end;    
    end loop;
  end diff_object;
  
  procedure diff_views
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    diff_object(v_schema1, v_schema2, c_type_view); 
  end diff_views;
  
  procedure missing_mviews
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    for i in (select mview_name
                from dba_mviews
               where owner=v_schema1
              minus 
              select mview_name
                from dba_mviews
               where owner=v_schema2             
             )
    loop
      write_missing(c_type_mview, i.mview_name, v_schema2);    
    end loop;
  end missing_mviews;
  
  procedure get_common_mviews
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2);   
  begin
    delete admin.common_objects where object_type=c_type_mview;
    insert into admin.common_objects (name, object_type)
    select mview_name
           ,c_type_mview
      from (select mview_name
              from dba_mviews
             where owner=v_schema1
            intersect
            select mview_name
              from dba_mviews
             where owner=v_schema2
           );
  end get_common_mviews;

  procedure do_compare_alter
    (i_schema1 in varchar2, i_schema2 in varchar2, i_name in varchar2, i_object_type in varchar2) 
  is
    v_object_type varchar2(30) := upper(i_object_type);
    v_name varchar2(30) := upper(i_name);
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
    alterddl clob;  
  begin
    alterddl := dbms_metadata_diff.compare_alter 
      (object_type   => v_object_type,
       name1         => i_name,
       name2         => i_name,
       schema1       => v_schema1,
       schema2       => v_schema2);
    
    if (dbms_lob.getlength(alterddl) > 0)      
    then
      write_diff(v_object_type, v_name, alterddl, null);
    end if;    
  end do_compare_alter;


  procedure diff_mviews
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
    alterddl clob;  
  begin
    for i in (select name from admin.common_objects where object_type = c_type_mview)
    loop
      do_compare_alter(v_schema1, v_schema2, i.name, c_type_mview);
    end loop;
  end diff_mviews;

  procedure missing_mview_logs
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    for i in (select master
                from dba_mview_logs
               where log_owner=v_schema1
              minus 
              select master
                from dba_mview_logs
               where log_owner=v_schema2
             )
    loop
      write_missing(c_type_mview_log, 'on table '||i.master, v_schema2);   
    end loop;
  end missing_mview_logs;

  procedure get_common_mview_logs
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2);   
  begin
    delete admin.common_objects where object_type=c_type_mview_log;
    insert into admin.common_objects (name, object_type)
    select master
           ,c_type_mview_log
      from (select master
              from dba_mview_logs
             where log_owner=v_schema1
            intersect
            select master
              from dba_mview_logs
             where log_owner=v_schema2
           );
  end get_common_mview_logs;
  
  procedure diff_mview_logs
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
    alterddl clob;  
  begin
    for i in (select name from admin.common_objects where object_type = c_type_mview_log)
    loop
      do_compare_alter(v_schema1, v_schema2, i.name, c_type_mview_log);
    end loop;
  end diff_mview_logs;

  procedure missing_indexes
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    for i in (select index_name
                from dba_indexes 
               where owner=v_schema1
                 and generated='N'
              minus 
              select index_name
                from dba_indexes
               where owner=v_schema2             
                 and generated='N'
             )
    loop
      write_missing(c_type_index, i.index_name, v_schema2);   
    end loop;
  end missing_indexes;
  
  procedure get_common_indexes
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    delete admin.common_objects where object_type=c_type_index;
    insert into admin.common_objects (name, object_type)
    select index_name
           ,c_type_index
      from (select index_name
                from dba_indexes 
               where owner=v_schema1
                 and generated='N'
              intersect
              select index_name
                from dba_indexes
               where owner=v_schema2             
                 and generated='N'
           );
  end get_common_indexes;

  procedure diff_indexes
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    diff_object(v_schema1, v_schema2, c_type_index); 
  end diff_indexes;

  procedure missing_triggers
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    for i in (select trigger_name
                from dba_triggers
               where owner=v_schema1
              minus 
              select trigger_name
                from dba_triggers
               where owner=v_schema2             
             )
    loop
      write_missing(c_type_trigger, i.trigger_name, v_schema2);   
    end loop;
  end missing_triggers;

  procedure get_common_triggers
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    delete admin.common_objects where object_type=c_type_trigger;
    insert into admin.common_objects (name, object_type)
    select trigger_name
           ,c_type_trigger
      from (select trigger_name
                from dba_triggers
               where owner=v_schema1
              intersect 
              select trigger_name
                from dba_triggers
               where owner=v_schema2 
           );
  end get_common_triggers;

  procedure diff_triggers
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    diff_object(v_schema1, v_schema2, c_type_trigger); 
  end diff_triggers;

  procedure missing_synonyms
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    for i in (select synonym_name
                from dba_synonyms
               where owner=v_schema1
              minus 
              select synonym_name
                from dba_synonyms
               where owner=v_schema2             
             )
    loop
      write_missing(c_type_synonym, i.synonym_name, v_schema2);   
    end loop;
  end missing_synonyms;

  procedure get_common_synonyms
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    delete admin.common_objects where object_type=c_type_synonym;
    insert into admin.common_objects (name, object_type)
    select synonym_name
           ,c_type_synonym
      from (select synonym_name
              from dba_synonyms
             where owner=v_schema1
            intersect
            select synonym_name
             from dba_synonyms
            where owner=v_schema2
           );
  end get_common_synonyms;

  procedure diff_synonyms
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    diff_object(v_schema1, v_schema2, c_type_synonym); 
  end diff_synonyms;

  procedure missing_sequences
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    for i in (select sequence_name
                from dba_sequences
               where sequence_owner=v_schema1
              minus 
              select sequence_name
                from dba_sequences
               where sequence_owner=v_schema2             
             )
    loop
      write_missing(c_type_sequence, i.sequence_name, v_schema2);
    end loop;
  end missing_sequences;

  procedure get_common_sequences
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    delete admin.common_objects where object_type=c_type_sequence;
    insert into admin.common_objects (name, object_type)
    select sequence_name
           ,c_type_sequence
      from (select sequence_name
              from dba_sequences
             where sequence_owner=v_schema1
            intersect 
            select sequence_name
              from dba_sequences
             where sequence_owner=v_schema2   
           );
  end get_common_sequences;
  
  procedure reset_seq_start
    (i_schema1 in varchar2, i_schema2 in varchar2, i_sequence_name in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
    v_sequence_name varchar2(30) := upper(i_sequence_name); 
  begin
    for i in (select sequence_owner  
                     ,last_number
                     ,max(last_number) over () as max_last_number
                from dba_sequences
               where sequence_owner in (v_schema1, v_schema2)
                 and sequence_name = v_sequence_name
             )
    loop
      if (i.last_number < i.max_last_number)
      then      
        dbms_output.put_line('INFO: alter sequence '||i.sequence_owner||'.'||v_sequence_name||' restart start with '||i.max_last_number);  
        execute immediate 'alter sequence '||i.sequence_owner||'.'||v_sequence_name||' restart start with '||i.max_last_number;
      end if;
    end loop;  
  end reset_seq_start;

  procedure diff_sequences
    (i_schema1 in varchar2, i_schema2 in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
    alterddl clob;
  begin
    for i in (select name from admin.common_objects where object_type = c_type_sequence)
    loop
      reset_seq_start(v_schema1, v_schema2, i.name);
      do_compare_alter(v_schema1, v_schema2, i.name, c_type_sequence);     
    end loop;
  end diff_sequences;

  procedure missing_stored_proc
    (i_schema1 in varchar2, i_schema2 in varchar2, i_object_type in dba_procedures.object_type%type) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
    v_object_type dba_procedures.object_type%type := upper(i_object_type);
  begin
    for i in (select distinct object_name
                from dba_procedures
               where owner=v_schema1
                 and object_type=v_object_type
               minus 
              select distinct object_name
                from dba_procedures
               where owner=v_schema2
                 and object_type=v_object_type
             )
    loop
      write_missing(v_object_type, i.object_name, v_schema2);
    end loop;
  end missing_stored_proc;

  procedure get_common_stored_proc
    (i_schema1 in varchar2, i_schema2 in varchar2, i_object_type in dba_procedures.object_type%type) 
  is
    v_object_type dba_procedures.object_type%type := upper(i_object_type);
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    delete admin.common_objects where object_type=v_object_type;
    insert into admin.common_objects (name, object_type)
    select object_name
           ,v_object_type
      from (select distinct object_name
                from dba_procedures
               where owner=v_schema1
                 and object_type=v_object_type
              intersect 
              select distinct object_name
                from dba_procedures
               where owner=v_schema2
                 and object_type=v_object_type
           );
  end get_common_stored_proc;

  procedure diff_stored_proc
    (i_schema1 in varchar2, i_schema2 in varchar2, i_object_type in dba_procedures.object_type%type) 
  is
    v_object_type dba_procedures.object_type%type := upper(i_object_type);
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    for i in (select name from admin.common_objects where object_type = v_object_type)
    loop
      declare
        ddl1 clob;
        ddl2 clob;
        is_different pls_integer;
      begin
        ddl1 := get_ddl(v_schema1,i.name,v_object_type);
        ddl2 := get_ddl(v_schema2,i.name,v_object_type);
      
        is_different := dbms_lob.compare (lob_1  => ddl1,  lob_2  => ddl2);
        
        if (is_different != 0)
        then
          write_diff(v_object_type, i.name, 'schema '||v_schema1||':'||ddl1, 'schema '||v_schema2||':'||ddl2);
        end if;
      end;    
    end loop;
  end diff_stored_proc;

  procedure do_stored_proc
    (i_schema1 in varchar2, i_schema2 in varchar2, i_stored_proc_type in varchar2) 
  is
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    missing_stored_proc(v_schema1, v_schema2, i_stored_proc_type);
    missing_stored_proc(v_schema2, v_schema1, i_stored_proc_type);
    get_common_stored_proc(v_schema1, v_schema2, i_stored_proc_type);
    diff_stored_proc(v_schema1, v_schema2, i_stored_proc_type);
  end do_stored_proc;
  
  ---------------------------------------------------------------------
  -- public
  ---------------------------------------------------------------------
  procedure compare
    (i_schema1 in varchar2, i_schema2 in varchar2, i_save_result number) 
  is  
    v_schema1 varchar2(30) := upper(i_schema1); 
    v_schema2 varchar2(30) := upper(i_schema2); 
  begin
    b_save_result := i_save_result > 0;
    
    verify_schemas(v_schema1,v_schema2);
        
    -- tables
    dbms_output.put_line('-------------------------------- comparing tables');
    missing_tables(v_schema1,v_schema2);
    missing_tables(v_schema2,v_schema1);
    get_common_tables(v_schema1,v_schema2);
    diff_tables(v_schema1,v_schema2); 
	
    -- views
    dbms_output.put_line('-------------------------------- comparing views');
    missing_views(v_schema1,v_schema2);
    missing_views(v_schema2,v_schema1);
    get_common_views(v_schema1,v_schema2);  
    diff_views(v_schema1,v_schema2); 

    -- mat views
    dbms_output.put_line('-------------------------------- comparing materialized views');
    missing_mviews(v_schema1,v_schema2);
    missing_mviews(v_schema2,v_schema1);
    get_common_mviews(v_schema1,v_schema2);  
    diff_mviews(v_schema1,v_schema2); 
    
    -- mat view logs
    dbms_output.put_line('-------------------------------- comparing materialized view logs');
    missing_mview_logs(v_schema1,v_schema2);
    missing_mview_logs(v_schema2,v_schema1);
    get_common_mview_logs(v_schema1,v_schema2);  
    diff_mview_logs(v_schema1,v_schema2); 
    
    -- indexes
    dbms_output.put_line('-------------------------------- comparing indexes');
    missing_indexes(v_schema1,v_schema2);
    missing_indexes(v_schema2,v_schema1);
    get_common_indexes(v_schema1,v_schema2);
    diff_indexes(v_schema1,v_schema2); 
    
    -- triggers
    dbms_output.put_line('-------------------------------- comparing triggers');
    missing_triggers(v_schema1,v_schema2);
    missing_triggers(v_schema2,v_schema1);
    get_common_triggers(v_schema1,v_schema2);
    diff_triggers(v_schema1,v_schema2); 
    
    -- synonyms
    dbms_output.put_line('-------------------------------- comparing synonyms');
    missing_synonyms(v_schema1,v_schema2);
    missing_synonyms(v_schema2,v_schema1);
    get_common_synonyms(v_schema1,v_schema2);
    diff_synonyms(v_schema1,v_schema2); 
    
    -- sequences
    dbms_output.put_line('-------------------------------- comparing sequences');
    missing_sequences(v_schema1,v_schema2);
    missing_sequences(v_schema2,v_schema1);
    get_common_sequences(v_schema1,v_schema2);
    diff_sequences(v_schema1,v_schema2); 
     
    -- packages
    dbms_output.put_line('-------------------------------- comparing packages');
    do_stored_proc(v_schema1,v_schema2, c_type_package); 

    -- procedures
    dbms_output.put_line('-------------------------------- comparing procedures');
    do_stored_proc(v_schema1,v_schema2, c_type_procedure); 
    
    -- functions
    dbms_output.put_line('-------------------------------- comparing functions');
    do_stored_proc(v_schema1,v_schema2, c_type_function); 

    -- types  
    dbms_output.put_line('-------------------------------- comparing types');
    do_stored_proc(v_schema1,v_schema2, c_type_type); 
    
    commit;
  end compare;
end;
/
