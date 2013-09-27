-- run as sysdba
WHENEVER SQLERROR EXIT SQL.SQLCODE

set serveroutput on size 1000000

accept SCHEMA prompt 'purge application data in schema: '

--
-- verify input schema exists
--
set verify off
set feedback off
col schema_exists new_value schema_exists
select count(*) as schema_exists from dba_tables where table_name='SCHEMA_MAP' and owner=UPPER('&SCHEMA');

begin
  if '&schema_exists' <> 1 then
    raise_application_error (-20101, 'input schema '||UPPER('&SCHEMA')||' does not exist!');
  end if;
end;
/

--
-- generate truncate table statements
--
select 'truncate table '||owner||'.'||t.tablename||';' 
  from dba_tables 
 cross join (select 'USER_TRANSACTIONS' as tablename from dual union all
             select 'GAME_HAND_TRANSACTION' as tablename from dual union all
             select 'GAME_HAND_SUMMARY' as tablename from dual union all
             select 'GAME_USER_HAND_SUMMARY' as tablename from dual union all
             select 'TGAME_HAND_TRANSACTION' as tablename from dual union all
             select 'TGAME_HAND_SUMMARY' as tablename from dual union all
             select 'TGAME_USER_HAND_SUMMARY' as tablename from dual union all
             select 'RAKE_PER_PLAYER_LOG' as tablename from dual union all
             select 'RISK_LOG' as tablename from dual union all
             select 'RISK_LOG_BACKUP' as tablename from dual union all
             select 'STAT5MIN' as tablename from dual) t
 where table_name='SCHEMA_MAP'
   and owner = UPPER('&SCHEMA');

set verify on
set feedback on