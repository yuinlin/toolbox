--
-- synchronize sequence value with value in tab columns
--
set serveroutput on size 1000000

WHENEVER SQLERROR EXIT SQL.SQLCODE

accept SCHEMA prompt'synchronize sequences for schema: '
accept DRYRUN prompt'do dry run (y/n)?: '


--
-- verify current user is same as input schema
--
undefine current_user

set verify off
col current_user new_value current_user
select user current_user from dual;

begin
  if upper('&current_user') <> upper('&SCHEMA') then
    raise_application_error (-20101, 'must run script as '||'&SCHEMA'||'!');
  end if;
end;
/

set verify on

declare
  type seq_aatype is table of user_sequences%ROWTYPE index by pls_integer;
  seq_aa seq_aatype;
  type nameidx_aatype is table of pls_integer index by user_sequences.sequence_name%TYPE;
  nameidx_aa nameidx_aatype;
begin
  --
  -- bulk fetch user_sequence info into assoc array, and create a 'sequence name index' for this array
  select * bulk collect into seq_aa from user_sequences s;
  for i in nvl(seq_aa.FIRST,0) .. nvl(seq_aa.LAST,1) loop
    nameidx_aa(seq_aa(i).sequence_name) := i;
  end loop;
  --
  --
  for i in (select * from x_allsequences) loop
    declare
      maxval int :=0;
      seq_aa_idx pls_integer;
      maxvalue_clause varchar2(300);
      minvalue_clause varchar2(300);
      cycle_clause varchar2(30);
      cache_clause varchar2(30);
      order_clause varchar2(30);
    begin
      if i.comments is null or lower(i.comments) not like '%not used%' then
        dbms_output.put_line ('======================================');
        --
        -- get max value from table
        if i.comments is null then
          execute immediate 'select nvl(max('||i.sequence_column||'),0) from '||i.table_name into maxval;
          dbms_output.put_line (i.table_name||'.'||i.sequence_column||' curr max value: '||maxval);
        -- tables/columns that need special handling
        elsif lower(i.comments) like '%lpad%' then
          execute immediate 'select nvl(max(substr('||i.sequence_column||',5)),0) from '||i.table_name into maxval;
          dbms_output.put_line (i.table_name||'.'||i.sequence_column||' curr max value: '||maxval);
        elsif lower(i.comments) like '%share%' then
          declare           
            v_tables x_allsequences.table_name%type := replace(i.table_name,' ','');
            v_sequence_column x_allsequences.sequence_column%type := i.sequence_column;
            tabcount number := 1 + length(v_tables) - length(replace(v_tables,',',''));
          begin
            for i in 1..tabcount loop
              declare
                v_currmaxval int;
                v_table user_tables.table_name%type;
                v_end_pos pls_integer;
              begin
                v_end_pos := case instr(v_tables,',')
                             when 0 then length(v_tables) 
                             else instr(v_tables,',')-1 end;
                v_table := substr(v_tables,1,v_end_pos);
                --
                execute immediate 'select nvl(max('||v_sequence_column||'),0) from '||v_table into v_currmaxval;
                dbms_output.put_line (v_table||'.'||v_sequence_column||' curr max value: '||v_currmaxval);                
                --
                v_tables := substr(v_tables,v_end_pos+2);
                if nvl(v_currmaxval,0) > maxval then
                  maxval := v_currmaxval;
                end if;
              end;
            end loop;
          end;
        end if;
        --
        -- drop and recreate sequence if needed
        --
        -- find sequence last number (actually the nextval)
        seq_aa_idx := nameidx_aa(i.sequence_name);
        dbms_output.put_line (seq_aa(seq_aa_idx).sequence_name||' current last number: '||seq_aa(seq_aa_idx).last_number);
        --
        -- drop and recreate if sequence lags table max value, or if sequence leads table max value by 500 or more
        if seq_aa(seq_aa_idx).last_number < maxval or
           seq_aa(seq_aa_idx).last_number >= (maxval+500)
        then
          --
          minvalue_clause := ' MINVALUE '||seq_aa(seq_aa_idx).min_value||' ';
          maxvalue_clause := ' MAXVALUE '||seq_aa(seq_aa_idx).max_value||' ';
          --
          if seq_aa(seq_aa_idx).cycle_flag='N' then
            cycle_clause := ' NOCYCLE ';
          else
            cycle_clause := ' CYCLE ';
          end if;
          --
          if nvl(seq_aa(seq_aa_idx).cache_size,0) <> 0 then
            cache_clause := ' CACHE '||seq_aa(seq_aa_idx).cache_size||' ';
          else
            cache_clause := ' NOCACHE ';
          end if;
          --
          if seq_aa(seq_aa_idx).order_flag='N' then
            order_clause := ' NOORDER ';
          else order_clause := ' ORDER ';
          end if;
          --
          dbms_output.put_line('==== executing following DDL:');
          dbms_output.put_line('drop sequence '||seq_aa(seq_aa_idx).sequence_name);
          dbms_output.put_line('create sequence '||seq_aa(seq_aa_idx).sequence_name);
          dbms_output.put_line(' increment by '||seq_aa(seq_aa_idx).increment_by);
          dbms_output.put_line(' start with '||(maxval+1));
          dbms_output.put_line(maxvalue_clause);
          dbms_output.put_line(minvalue_clause);
          dbms_output.put_line(cycle_clause);
          dbms_output.put_line(cache_clause);
          dbms_output.put_line(order_clause);
          --
    if nvl(lower('&DRYRUN'),'y') <> 'y' then
            execute immediate 'drop sequence '||seq_aa(seq_aa_idx).sequence_name;
            execute immediate 'create sequence '||seq_aa(seq_aa_idx).sequence_name||
                              ' increment by '||seq_aa(seq_aa_idx).increment_by||
                              ' start with '||to_number(maxval+1)||
                              maxvalue_clause||
                              minvalue_clause||
                              cycle_clause||
                              cache_clause||
                              order_clause;
          end if;
          --
        end if;
      end if;
    exception when others then
      dbms_output.put_line ('==== err processing seq '||i.sequence_name||' for '||i.table_name||'.'||i.sequence_column||': '||SQLERRM);
    end;
  end loop;
  --
  if nvl(lower('&DRYRUN'),'y') = 'y' then
    dbms_output.put_line('==== ');
    dbms_output.put_line('done dry run; no ddl executed!');
    dbms_output.put_line('==== ');
  end if;
  --
end;
/
