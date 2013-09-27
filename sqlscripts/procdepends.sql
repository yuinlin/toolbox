set pagesize 0

prompt "top level procedures"
select distinct name from user_dependencies where type = 'PROCEDURE'
and name not in (select referenced_name from user_dependencies)
/

prompt "procedures invoked by others"
select distinct name from user_dependencies where type = 'PROCEDURE'
minus
select distinct name from user_dependencies where type = 'PROCEDURE'
and name not in (select referenced_name from user_dependencies)
/

prompt "packages"
select object_name from user_objects where object_type='PACKAGE'
/

