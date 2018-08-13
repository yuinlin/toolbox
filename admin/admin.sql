create tablespace admin datafile size 200M autoextend off;

define SCHEMANAME=admin
   create user &SCHEMANAME identified by admin
   default tablespace admin
   quota unlimited on admin
   temporary tablespace temp;
   
   grant create session to &SCHEMANAME;
   grant create table to &SCHEMANAME;
   grant create procedure to &SCHEMANAME;

   grant inherit privileges on user sys to &SCHEMANAME;     
   
   grant select on gv_$session to &SCHEMANAME;
   grant select on dba_users to &SCHEMANAME;
   grant select on dba_tablespaces to &SCHEMANAME;
   grant select on dba_ts_quotas to &SCHEMANAME;
   grant select on dba_segments to &SCHEMANAME;
   grant select on dba_tables to &SCHEMANAME;
   grant select on dba_tab_columns to &SCHEMANAME;
   grant select on dba_views to &SCHEMANAME;
   grant select on dba_mviews to &SCHEMANAME; 
   grant select on dba_mview_logs to &SCHEMANAME;
   grant select on dba_indexes to &SCHEMANAME;
   grant select on dba_triggers to &SCHEMANAME;
   grant select on dba_synonyms to &SCHEMANAME;
   grant select on dba_sequences to &SCHEMANAME;
   grant select on dba_procedures to &SCHEMANAME; 
undef SCHEMANAME

