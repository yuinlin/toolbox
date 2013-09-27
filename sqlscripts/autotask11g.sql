-- display info about automatic stats gathering job in 11g
select client_name, status, attributes, total_cpu_last_7_days, max_duration_last_7_days, window_duration_last_7_days 
  from dba_autotask_client;


select * from dba_autotask_window_clients;
