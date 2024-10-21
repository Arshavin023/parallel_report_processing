Refresh database
- VACUUM VERBOSE;

Monitor Database health
SELECT pid,usename AS username,datname AS database_name,application_name,client_addr AS client_address,
    state,query,backend_start,state_change,now() - query_start AS query_duration
FROM pg_stat_activity
WHERE state <> 'idle' AND pid <> pg_backend_pid()  -- Exclude the current session
ORDER BY query_start;


SELECT schemaname || '.' || relname AS table_name,seq_scan,seq_tup_read AS sequential_rows_read,idx_scan,
    idx_tup_fetch AS index_rows_fetched,n_tup_ins AS rows_inserted,n_tup_upd AS rows_updated,n_tup_del AS rows_deleted,
	n_live_tup AS live_rows,n_dead_tup AS dead_rows,last_vacuum,last_autovacuum,last_analyze,last_autoanalyze
FROM pg_stat_user_tables
ORDER BY relname;
