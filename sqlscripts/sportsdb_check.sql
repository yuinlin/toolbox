alter session set nls_date_format='MM/DD/RR HH24:MI:SS';
set serveroutput on size 1000000
set lines 240 pages 200
col load_message form a70

select count(*) as "LOAD ERROR HISTORY COUNT" from load_info_history;

prompt CURRENT LOAD STATS:
select * from load_info;
