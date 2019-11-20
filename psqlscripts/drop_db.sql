\set ON_ERROR_STOP on 

\pset tuples_only on
\prompt 'db to drop: ' drop_db

select 'grant database ' || :'drop_db' ||' to '||current_user||';';
select 'alter database ' || :'drop_db' ||' owner to '||current_user||';';
select 'drop database ' || :'drop_db' ||';';
select 'drop role '|| (select pg_get_userbyid(datdba) from pg_database where datname=:'drop_db') || ';';

\pset tuples_only off
