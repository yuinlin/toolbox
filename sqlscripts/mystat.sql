select a.name, b.value
  from v$statname a, v$mystat b
 where a.statistic# = b.statistic#
   and lower(a.name) like '%' || lower('&1')||'%'
   and b.value > 0;