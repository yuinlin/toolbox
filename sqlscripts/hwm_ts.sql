rem
rem Script:  ts_hwm.sql
rem Author:  Jonathan Lewis
rem Dated:  Feb 2010
rem Purpose:
rem
rem Last tested
rem  11.2.0.3
rem  11.1.0.7
rem  10.2.0.3
rem Not tested
rem  10.2.0.5
rem   9.2.0.8
rem   8.1.7.4
rem Not relevant
rem
rem Notes:
rem Quick and dirty to list extents in a tablespace
rem in file and block order.
rem
rem For LMTs, expect to acquire one TT lock per segment
rem in the tablespace, and to query seg$ once for each
rem segment in the tablespace.  This is a side effect of
rem the mechanism invoked by accessing x$ktfbue. Also
rem assume that you will do one phsyical block read per
rem segment (reading the segment header block for the
rem extent map) as this is also part of the implementation
rem of x$ktfbue.
rem
rem Watch out for objects in the recyclebin - they will show
rem up as FREE in dba_free_space, but will stop you from
rem resizing the tablespace until you purge them. Depending
rem on version of Oracle you may get some clues about this
rem because each "free" extent in the recyclebin is reported
rem as a separate extent by dba_free_space.
rem
 
define m_tablespace = 'TEST_8K'
 
select
    file_id,
    block_id,
    block_id + blocks - 1   end_block,
    owner,
    segment_name,
    partition_name,
    segment_type
from
    dba_extents
where
    tablespace_name = '&m_tablespace'
union all
select
    file_id,
    block_id,
    block_id + blocks - 1   end_block,
    'free'          owner,
    'free'          segment_name,
    null            partition_name,
    null            segment_type
from
    dba_free_space
where
    tablespace_name = '&m_tablespace'
order by
    1,2
/