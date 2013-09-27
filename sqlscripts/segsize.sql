set pagesize 60
col segment_name form a30
col segment_type form a30
col table_name form a30
col mb form 99999999

accept i_owner prompt "show segments size for schema: "

select v.segment_name
       ,v.segment_type
       ,v.table_name
       ,sum(v.bytes)/1024/1024 as MB 
  from (select s.segment_name
               ,case when s.segment_type in ('INDEX','LOBINDEX') then i.table_name
                     when s.segment_type = 'LOBSEGMENT' then l.table_name
                     else s.segment_name
                     end as table_name
               ,s.segment_type
               ,s.bytes
          from dba_segments s
          left outer join
               dba_indexes i
            on (i.owner = s.owner and
                i.index_name = s.segment_name)
          left outer join
               dba_lobs l
            on (l.owner = s.owner and
                l.segment_name = s.segment_name)
         where s.owner = upper('&i_owner')
       ) v
 group by v.segment_name, v.segment_type, v.table_name order by MB;