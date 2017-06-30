-- as user admin

create or replace package admin_utl
authid current_user
as
  tablespace_not_online exception;
  pragma exception_init(tablespace_not_online, -01539);

  cannot_drop_connected_user exception;
  pragma exception_init(cannot_drop_connected_user, -01940);

  oracle_owned_schema exception;
  
  subtype non_null_objectname is varchar2(30) not null; 
  subtype non_null_string4000 is varchar2(4000) not null; 

  c_file_max_gb constant pls_integer := 30;
  c_tablespace_prefix constant char(6) := 'USERS_';
 
  g_debug_mode boolean := false;
  
  procedure create_default_tablespace
    (i_debug_mode in boolean default false);

  procedure drop_archived_tablespace
    (i_months_prior in number default 2
     ,i_debug_mode in boolean default false);
     
  procedure force_drop_user
    (i_user_name in varchar2
     ,i_debug_mode in boolean default false);
end;
/

create or replace package body admin_utl
as 
  procedure do_ddl
    (i_ddl in non_null_string4000)
  is  
  begin    
    dbms_output.put_line('-- '||i_ddl);
    if (not g_debug_mode) then
      execute immediate i_ddl;
    end if;
  end do_ddl;  

  procedure create_tablespace
    (i_tablespace_name in non_null_objectname
     ,i_tablespace_max_gb in number default 10)
  is  
    v_file_count pls_integer;
  begin    
    v_file_count := ceil(i_tablespace_max_gb/c_file_max_gb);
    if (v_file_count = 1) then
      do_ddl('create tablespace '||i_tablespace_name||' datafile size 200M autoextend on maxsize '||i_tablespace_max_gb*1024||'M');
    else
      do_ddl('create tablespace '||i_tablespace_name||' datafile size 200M autoextend on maxsize '||c_file_max_gb*1024||'M');
      for i in 1..(v_file_count-1) loop
        do_ddl('alter tablespace '||i_tablespace_name||' add datafile size 200M autoextend on maxsize '||c_file_max_gb*1024||'M');
      end loop;
    end if;
  end create_tablespace;  
  
  procedure set_default_tablespace
    (i_tablespace_name in non_null_objectname)
  is  
  begin
    do_ddl('alter database default tablespace '||i_tablespace_name);
  end set_default_tablespace; 

  procedure set_existing_user_tablespace
  is
  begin
    -- if a user inherited their default tablespace from db default tablespace value
    -- but they have quota granted on a different tablespace, change their default 
    -- tablespace to match the quota'ed one
    for i in (
              select u.username
                     ,q.tablespace_name as quota_granted_tablespace
                from dba_users u
                left outer join dba_ts_quotas q
                  on (q.username = u.username)
               where u.oracle_maintained = 'N'
                 and q.dropped = 'NO'
                 and u.default_tablespace = (select property_value 
                                               from database_properties 
                                              where property_name='DEFAULT_PERMANENT_TABLESPACE')
                 and u.default_tablespace <> q.tablespace_name
             ) 
    loop
      do_ddl('alter user '||i.username||' default tablespace '||i.quota_granted_tablespace);
    end loop;
  end set_existing_user_tablespace;
 
  procedure drop_tablespace
    (i_tablespace_name in non_null_objectname)
  is  
  begin    
    begin
      do_ddl('alter tablespace '||i_tablespace_name||' offline');
    exception when tablespace_not_online then
      null;
    end;
    do_ddl('drop tablespace '||i_tablespace_name||' including contents and datafiles');
  end drop_tablespace;

  function is_oracle_owned
    (i_user in non_null_objectname)
  return varchar2    
  is
    v_oracle_owned varchar2(1) := 'n';
  begin
    $if dbms_db_version.ver_le_11 $then
      select case when created - (select min(created) from dba_users) <= 1 then 'y' else 'n' end
        into v_oracle_owned
        from dba_users 
       where username=i_user;
    $else
      select lower(oracle_maintained) into v_oracle_owned from dba_users where username=i_user;
    $end       
    return v_oracle_owned;
  exception when no_data_found then
    return v_oracle_owned;
  end is_oracle_owned;
  
  procedure lock_user
    (i_user in non_null_objectname)
  is
    v_user dba_users.username%type := upper(i_user); 
  begin
    if is_oracle_owned(v_user) = 'y' then
      raise oracle_owned_schema;
    end if;       
    do_ddl('alter user '||v_user||' account lock');
  end lock_user;

  procedure drop_user
    (i_user in non_null_objectname
     ,i_cascade in boolean default false)
  is
    v_user dba_users.username%type := upper(i_user); 
  begin
    if is_oracle_owned(v_user) = 'y' then
      raise oracle_owned_schema;
    end if;
    if i_cascade then
      do_ddl('drop user '||v_user||' cascade');
    else
      do_ddl('drop user '||v_user);
    end if;
  end drop_user;

  procedure lock_and_drop_users
    (i_tablespace_name in non_null_objectname)
  is
  begin
    for i in (select distinct owner 
                from dba_segments 
               where tablespace_name = upper(i_tablespace_name)
             )
    loop
      lock_user(i.owner);
      drop_user(i.owner, true);
    end loop;
  end lock_and_drop_users;
 
  procedure create_default_tablespace
    (i_debug_mode in boolean default false)  
  is  
    v_curr_tablespace varchar2(30) := c_tablespace_prefix||to_char(sysdate,'yyyymm');
    v_tablespace_is_default pls_integer := 0;
    v_tablespace_exists pls_integer := 0;
  begin 
    g_debug_mode := i_debug_mode;
    
    select count(*)
      into v_tablespace_is_default
      from database_properties
     where property_name = 'DEFAULT_PERMANENT_TABLESPACE'
       and property_value = v_curr_tablespace;    
    
    if (v_tablespace_is_default = 1) then
      dbms_output.put_line('tablespace '||v_curr_tablespace||' is already the default tablespace');
      return;
    end if;
    
    select count(*)
      into v_tablespace_exists
      from dba_tablespaces
     where tablespace_name = v_curr_tablespace;
    
    if (v_tablespace_exists != 1) then
      create_tablespace(v_curr_tablespace);
    end if;
    
    set_default_tablespace(v_curr_tablespace);
    set_existing_user_tablespace;
  end create_default_tablespace;
  
  procedure drop_archived_tablespace
    (i_months_prior in number default 2
     ,i_debug_mode in boolean default false)
  is  
    v_found_ts_to_drop boolean := false;
    v_yearmonth pls_integer;
  begin       
    g_debug_mode := i_debug_mode;
    
    select to_number(to_char(add_months(sysdate, -1 * i_months_prior),'yyyymm'))
      into v_yearmonth
      from dual;      
      
    for i in (select tablespace_name 
                from dba_tablespaces
               where instr(tablespace_name, c_tablespace_prefix) = 1
                 and regexp_substr(tablespace_name, c_tablespace_prefix||'(\d{6}?)$',1,1,'i',1) <= v_yearmonth
                 and contents = 'PERMANENT'
               order by tablespace_name
             )
    loop
      v_found_ts_to_drop := true;
      begin
        dbms_output.put_line('for tablespace '||i.tablespace_name);
        lock_and_drop_users(i.tablespace_name);
        -- take tablespace off and online to clear up any temporary segments in it
        do_ddl('alter tablespace '||i.tablespace_name||' offline'); 
        do_ddl('alter tablespace '||i.tablespace_name||' online'); 
        drop_tablespace(i.tablespace_name);
      exception when oracle_owned_schema then 
        dbms_output.put_line('tablespace '||i.tablespace_name||' contains oracle owned schema; cannot be dropped');
      end;
    end loop;

    if not (v_found_ts_to_drop) then
      dbms_output.put_line('no tablespace at or earlier than '||v_yearmonth||' was found to drop');
    end if;
  end drop_archived_tablespace;    
  
  procedure force_drop_user
    (i_user_name in varchar2
     ,i_debug_mode in boolean default false)
  is
    user_not_exist exception;
    pragma exception_init(user_not_exist, -01918);
  begin 
    g_debug_mode := i_debug_mode;
    
    lock_user(i_user_name);

    for i in (select s.sid, s.serial#
          from gv$session s
           where s.username = upper(i_user_name)
           and s.inst_id = sys_context('USERENV', 'INSTANCE')
             -- exclude current session from kill list
           and s.sid <> sys_context('USERENV', 'SID')
         )
    loop
      do_ddl('alter system kill session '''||i.sid||','||i.serial#||'''');
    end loop;
    
    drop_user(i_user_name, true);
  exception 
    when user_not_exist then 
      dbms_output.put_line('user '||i_user_name||' does not exist');
  end force_drop_user;	 
end;
/


/*

-- manual ts rotation:
-- as sys
set serveroutput on size 1000000
exec admin.admin_utl.create_default_tablespace(i_debug_mode => true);
exec admin.admin_utl.create_default_tablespace(i_debug_mode => false);
  
exec admin.admin_utl.drop_archived_tablespace(i_months_prior => 2, i_debug_mode => true);
exec admin.admin_utl.drop_archived_tablespace(i_months_prior => 2, i_debug_mode => false);



-- have not implemented below
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
   job_name           =>  '',
   job_type           =>  'STORED_PROCEDURE',
   job_action         =>  'admin_utl.',
   start_date         =>  ,
   repeat_interval    =>  'FREQ=MONTHLY;INTERVAL=1'
   comments           =>  '');
END;
/
*/

