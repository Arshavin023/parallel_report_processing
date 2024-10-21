--Generate summary report
TRUNCATE public.ods_count_monitoring;
CALL public.proc_loop_through_ods_tables();
