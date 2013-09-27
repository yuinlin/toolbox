col module format a8
col sql_text format a30
col opt_mode format a6
col sort_type format a8
col policy format a6
col last_exec format a8
col opt# format 99
col one# format 99
col multi# format 99

accept findme prompt 'enter sql string to find: '

select s.module
       ,s.sql_text
       ,s.optimizer_mode opt_mode
       ,w.operation_type sort_type
       ,w.policy
       ,w.last_execution last_exec
       ,w.optimal_executions opt#
       ,w.onepass_executions one#
       ,w.multipasses_executions multi#
  from v$sql s 
       ,v$sql_workarea w
 where s.sql_text like '%&findme%'
   and s.address = w.address
   and replace(s.sql_text,' ','')
       not like 'select%fromv$sqls,v$sql_workareaw%'
/



