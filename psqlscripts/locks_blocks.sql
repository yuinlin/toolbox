-- current blocked
 SELECT blocked_locks.pid     AS blocked_pid,
         blocked_activity.usename  AS blocked_user,
         blocking_locks.pid     AS blocking_pid,
         blocking_activity.usename AS blocking_user,
         blocked_activity.query    AS blocked_statement,
         blocking_activity.query   AS current_statement_in_blocking_process
   FROM  pg_catalog.pg_locks         blocked_locks
    JOIN pg_catalog.pg_stat_activity blocked_activity  ON blocked_activity.pid = blocked_locks.pid
    JOIN pg_catalog.pg_locks         blocking_locks 
        ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid
    JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
   WHERE NOT blocked_locks.GRANTED;

-- locks   
select l.pid 
       ,l.transactionid
       ,l.virtualxid
       ,l.virtualtransaction
       ,d.datname
       ,l.locktype
       ,l.mode
       ,l.relation::regclass relation
       ,l.classid::regclass as class
       ,l.page
       ,l.tuple
       ,case when not l.granted then 'BLOCKED' 
             when exists (select * from pg_locks bl 
                          where not bl.granted
                            and bl.locktype = l.locktype
                            AND bl.DATABASE IS NOT DISTINCT FROM l.DATABASE
                            AND bl.relation IS NOT DISTINCT FROM l.relation
                            AND bl.page IS NOT DISTINCT FROM l.page
                            AND bl.tuple IS NOT DISTINCT FROM l.tuple
                            AND bl.virtualxid IS NOT DISTINCT FROM l.virtualxid
                            AND bl.transactionid IS NOT DISTINCT FROM l.transactionid
                            AND bl.classid IS NOT DISTINCT FROM l.classid
                            AND bl.objid IS NOT DISTINCT FROM l.objid
                            AND bl.objsubid IS NOT DISTINCT FROM l.objsubid
                            AND bl.pid != l.pid) then 'Y: BLOCKER'                  
             else 'Y' 
             end as isgranted
  from pg_locks l
  left join pg_database d 
    on (d.oid = l.database)
 where d.datname = current_database()
    or (d.datname is null and exists (select * 
                                        from pg_locks ll 
                                        join pg_database dd 
                                          on (dd.oid = ll.database) 
                                       where dd.datname = current_database() 
                                         and ll.pid = l.pid))
 order by l.pid, l.granted;