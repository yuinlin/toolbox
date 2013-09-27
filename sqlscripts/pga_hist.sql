col pga_size format a25
col optimal format 9999999
col onepass format 9999999
col multipass format 9999999

SELECT case when low_optimal_size < 1024*1024
            then to_char(low_optimal_size/1024,'999999') ||
                 'kb <= PGA < ' ||
                 (HIGH_OPTIMAL_SIZE+1)/1024|| 'kb'
            else to_char(low_optimal_size/1024/1024,'999999') ||
                 'mb <= PGA < ' ||
                 (high_optimal_size+1)/1024/1024|| 'mb'
             end pga_size
       ,optimal_executions as optimal
       ,onepass_executions as onepass
       ,multipasses_executions as multipass
  from v$sql_workarea_histogram
 where total_executions <> 0
 order by low_optimal_size
/
