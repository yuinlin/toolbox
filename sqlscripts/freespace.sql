accept TS prompt "tablespace (default all, can do fuzzy match): "

set linesize 140
set verify off
col ts format a20
col dfile format a50
col freeMB format 999999999999.99

select s.tablespace_name ts
       ,f.file_name dfile
       ,(sum(s.bytes)/1024)/1024 freeMB
  from dba_free_space s
       ,dba_data_files f
 where s.file_id = f.file_id
   and ( ('&TS' is null)
          or
         (s.tablespace_name like upper('%&TS%'))
       )   
 group by s.tablespace_name, f.file_name
 order by s.tablespace_name, f.file_name;
