set pages 80
select * from v$sgastat where lower(name) like lower('%&1%');
