accept OWNER prompt 'schema: '
accept TABLE prompt 'table name: '
accept CHUNKS prompt 'number of chunks: '

select grp,
       dbms_rowid.rowid_create (1,data_object_id,lo_fno,lo_block,0) min_rid,
       dbms_rowid.rowid_create (1,data_object_id,hi_fno,hi_block,10000) max_rid
  from (select distinct grp,
               first_value(relative_fno) over (partition by grp 
                                                   order by relative_fno, block_id
                                                    rows between unbounded preceding
                                                             and unbounded following) lo_fno,
               first_value (block_id) over (partition by grp
                                                order by relative_fno, block_id                                        
                                                 rows between unbounded preceding
                                                          and unbounded following) lo_block,
               last_value (relative_fno) over (partition by grp
                                                order by relative_fno, block_id                                        
                                                 rows between unbounded preceding
                                                          and unbounded following) hi_fno,
               last_value (block_id+blocks-1) over (partition by grp
                                                order by relative_fno, block_id                                        
                                                 rows between unbounded preceding
                                                          and unbounded following) hi_block,
               sum(blocks) over (partition by grp) sum_blocks
          from (select relative_fno,
                       block_id,
                       blocks,
                       trunc( (sum(blocks) over (order by relative_fno, block_id)-0.01)/
                              (sum(blocks) over ()/&CHUNKS)
                            ) grp
                  from dba_extents
                 where segment_name = upper('&TABLE')
                   and owner = upper('&OWNER')
               )
       ),
       (select data_object_id
          from dba_objects
         where object_name = upper('&TABLE')
           and owner = upper('&OWNER'))
/



