select pid, backend_start, usename, xact_start, query_start, wait_event_type, wait_event, state, backend_xid, backend_xmin, query
from pg_stat_activity 
where pid <> pg_backend_pid() 
and datname = current_database();