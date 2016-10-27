
accept schema_name      prompt 'in schema: '
accept table_name       prompt 'on table: '
accept for_insert       prompt 'for insert [y/n]? '
accept for_update       prompt 'for update [y/n]? '
accept for_delete       prompt 'for delete [y/n]? '
accept delay_seconds    prompt 'delay until specified seconds from now: '

set verify off
set serveroutput on size 100000

declare 
   v_schema_name varchar2(30);
   v_table_name varchar2(30);
   v_dml varchar2(30);
   v_delay_seconds number(10,0);
   v_utc_time varchar2(100);
   c_timestamp_format constant varchar2(30) := 'dd-mm-yyyy hh24:mi:ss';
   v_trigger_name varchar2(30) := 'delay_'||to_char(sys_extract_utc(systimestamp),'yyyymmddhh24miss');
begin     
   begin
      select username into v_schema_name from dba_users where username=nvl(upper('&schema_name'),'invalid user');
   exception when no_data_found then
      raise_application_error (-20101, 'invalid schema &schema_name specified');
   end;

   begin
      select table_name into v_table_name from dba_tables where owner=v_schema_name and table_name=nvl(upper('&table_name'),'invalid table');
   exception when no_data_found then
      raise_application_error (-20101, 'invalid table &table_name specified');
   end;

   begin
      if nvl('&for_insert','n') != 'n' then
         v_dml := v_dml||' insert or';
      end if;
      if nvl('&for_update','n') != 'n' then
         v_dml := v_dml||' update or';
      end if;
      if nvl('&for_delete','n') != 'n' then
         v_dml := v_dml||' delete or';
      end if;
      if v_dml is null then
         raise_application_error (-20101, 'must specify at least one dml event (insert,update,delete)');
      else
         v_dml := rtrim(v_dml,' or');
      end if;
   end;

   begin
      v_delay_seconds := to_number(nvl('&delay_seconds','invalid number'));
      v_utc_time := to_char(sys_extract_utc(systimestamp) + numtodsinterval(v_delay_seconds,'second'),
                            c_timestamp_format);
   exception when value_error then
      raise_application_error (-20101, 'delay seconds must be an integer greater than 0');
   end;

   execute immediate ' create or replace trigger '||v_schema_name||'.'||v_trigger_name||
                     ' before '||v_dml||
		     ' on '||v_schema_name||'.'||v_table_name|| 	   	     
		     ' declare '||
		     '   v_until timestamp := to_timestamp('''||v_utc_time||''','''||c_timestamp_format||'''); '||
		     ' begin '||
		     '   while (sys_extract_utc(systimestamp) < v_until) loop '||
		     '      dbms_lock.sleep(.05); '||
		     '   end loop; '||
		     ' end;';

   dbms_output.put_line('============================');
   dbms_output.put_line('created delay');
   dbms_output.put_line('clean up delay with "drop trigger '||v_schema_name||'.'||v_trigger_name||';"');
   dbms_output.put_line('============================');
end;
/


undef schema_name
undef table_name
undef dml_type
undef delay_seconds
