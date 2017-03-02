create tablespace admin datafile size 200M autoextend off;

define SCHEMANAME=admin
   create user &SCHEMANAME identified by admin
   default tablespace admin
   quota unlimited on admin
   temporary tablespace temp;
   
   grant create session to &SCHEMANAME;
   grant create table to &SCHEMANAME;
   grant create procedure to &SCHEMANAME;

   grant inherit privileges on user sys to admin;     
   
   grant select on gv_$session to &SCHEMANAME;
   grant select on dba_users to &SCHEMANAME;
   grant select on dba_tablespaces to &SCHEMANAME;
   grant select on dba_segments to &SCHEMANAME;
   grant select on dba_tables to admin;
   grant select on dba_tab_columns to admin;
   grant select on dba_views to admin;
   grant select on dba_mviews to admin; 
   grant select on dba_mview_logs to admin;
   grant select on dba_indexes to admin;
   grant select on dba_triggers to admin;
   grant select on dba_synonyms to admin;
   grant select on dba_sequences to admin;
   grant select on dba_procedures to admin; 
undef SCHEMANAME

