select c.table_name
       ,c.column_name
       ,c.data_type
       ,case when c.data_type='NUMBER' then c.data_precision
             else c.data_length end as column_size
       ,(select cc.comments 
           from user_col_comments cc
          where cc.table_name = c.table_name
            and cc.column_name = c.column_name) as colcomment
  from user_tab_columns c
 where instr(c.table_name,'AT_',1) = 0
   and instr(c.table_name,'ADAPTER_GV',1) = 0
   and c.column_name in (select column_name 
                           from (select column_name
                                        ,data_length
                                        ,data_precision
                                        ,max(data_length) over (partition by column_name) as maxl
                                        ,max(data_precision) over (partition by column_name) as maxp
                                   from (select * 
                                           from user_tab_columns 
                                          where instr(table_name,'AT_',1) = 0 
                                            and instr(table_name,'ADAPTER_GV',1) = 0)) t
                                   where t.data_length <> t.maxl or t.data_precision <> t.maxp)
 order by column_name, table_name
/

