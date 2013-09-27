select s.sid
       ,t.used_ublk
       ,t.used_urec
       ,t.log_io
       ,t.phy_io
       ,t.cr_get
       ,CASE BITAND(t.flag, POWER(2, 28))
        WHEN 0 THEN 'READ COMMITTED'
        ELSE 'SERIALIZABLE' END as isolation_level
  from v$transaction t
       ,v$session s
 where t.addr = s.taddr 
/
