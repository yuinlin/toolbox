-- as sysdba, check and set parameter value if necessary

show parameter timed_statistics
-- alter system set timed_statistics = TRUE;


-- as user perfstat, take snapshots
var snapID number;
exec :snapID := statspack.snap;
print snapID;

-- ...work happens on db

-- take snap shot again

-- generate report for snapshot range
sqlplus> %ORACLE_HOME%\rdbms\admin\spreport


-- optional; purge snapshot info
sqlplus> %ORACLE_HOME%\rdbms\admin\sppurge