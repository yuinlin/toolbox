select
  trunc(pga_target_for_estimate/1024/1024) 
                         pga_target_MB,
  to_char(pga_target_factor * 100,'999.9') ||'%' 
                         pga_target_factor,
  trunc(bytes_processed/1024/1024) bytes_processed,
  trunc(estd_extra_bytes_rw/1024/1024) estd_extra_bytes_rw,
  to_char(estd_pga_cache_hit_percentage,'999') || '%' 
                         estd_pga_cache_hit_percentage,
  estd_overalloc_count
from v$pga_target_advice
/
