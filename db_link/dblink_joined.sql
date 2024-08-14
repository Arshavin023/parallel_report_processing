with temp_table as (
SELECT sf.facility_id filedb_sync_file_table_facility_id,
    sm.file_name AS lamisplus_dwh_stg_monitoring_table_file_name,
	sm.processed lamisplus_dwh_stg_monitoring_table_processed,
	sf.processed filedb_sync_file_table_processed,
	sm.load_time lamisplus_dwh_stg_monitoring_table_load_time,
	sf.ingest_end_time filedb_sync_file_table_ingest_load_time,
    sm.stg_rec_count AS lamisplus_dwh_stg_monitoring_table_rec_count,sf.json_rec_count filedb_sync_file_table_json_rec_count
FROM 
    dblink(
        'db_link_staging',
        'SELECT DISTINCT REPLACE(file_name, ''_decrypted.json'', ''.json'') AS file_name,
                load_time,processed,stg_rec_count
         FROM stg_monitoring 
         WHERE --processed = ''Y'' 
		--AND 
		load_time >= ''2024-06-01'' 
		and datim_id in (''f0J277xHATh'') and file_name is not null
         '
    ) AS sm(file_name VARCHAR, load_time TIMESTAMP,processed VARCHAR,stg_rec_count integer)
RIGHT JOIN 
    (select distinct file_name,processed,ingest_end_time,json_rec_count,ingest_error_message,facility_id
	from sync_file where create_date >= '2024-06-01' and facility_id in ('f0J277xHATh')
	 and json_rec_count is not null
	) sf ON sm.file_name = sf.file_name),
	
deduplication as (
select *,
	row_number () over (partition by lamisplus_dwh_stg_monitoring_table_file_name 
						order by filedb_sync_file_table_ingest_load_time desc) row_num
from temp_table
)

select cpm.ip_code,cpm.ip_name,cpm.datim_id,cpm.facility_name,
lamisplus_dwh_stg_monitoring_table_file_name,lamisplus_dwh_stg_monitoring_table_processed,
filedb_sync_file_table_processed,lamisplus_dwh_stg_monitoring_table_load_time,
filedb_sync_file_table_ingest_load_time,lamisplus_dwh_stg_monitoring_table_rec_count,
filedb_sync_file_table_json_rec_count
from deduplication d
left join central_partner_mapping cpm on d.filedb_sync_file_table_facility_id=cpm.datim_id
where row_num=1
order by lamisplus_dwh_stg_monitoring_table_processed desc