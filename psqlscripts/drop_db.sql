\set ON_ERROR_STOP on 

\pset tuples_only on
\prompt 'db to drop: ' drop_db

select 'alter database ' || :'drop_db' ||' owner to '||current_user||';'
       ||' '||
       'drop database ' || :'drop_db' ||';'
       ||' '||
       'drop role '|| (select pg_get_userbyid(datdba) from pg_database where datname=:'drop_db') || ';';

\pset tuples_only off
