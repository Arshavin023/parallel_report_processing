SELECT replace(table_name,'stg_','')table_name ,column_name,data_type,ordinal_position,character_maximum_length
FROM information_schema.columns
WHERE table_name ilike 'stg_%'
order by table_name asc;

SELECT 
    replace(table_name, 'ods_', '') AS table_name,
    column_name,
    data_type,
    ordinal_position,
    character_maximum_length
FROM 
    information_schema.columns
WHERE 
    table_name ~ '^ods_.*' -- Table names starting with 'ods_'
    AND table_name !~ '[0-9]$' -- Exclude table names ending with numbers
    AND table_name !~ '_old$' -- Exclude table names ending with '_old'
ORDER BY 
    table_name,column_name ASC;


CREATE TABLE lamisplus_sync_database_info AS
SELECT 
    replace(table_name, 'ods_', '') AS table_name,
    column_name,
    data_type,
    ordinal_position,
    character_maximum_length
FROM 
    information_schema.columns
WHERE 
    table_name ~ '^ods_.*' -- Table names starting with 'ods_'
    AND table_name !~ '[0-9]$' -- Exclude table names ending with numbers
    AND table_name !~ '_old$' -- Exclude table names ending with '_old'
ORDER BY 
    table_name,column_name ASC;

CREATE INDEX IF NOT EXISTS idx_tablecolumn_lamisplus_sync_database_info
ON lamisplus_sync_database_info(table_name,column_name);

CREATE INDEX IF NOT EXISTS idx_tablecolumn_lamisplus_client_database_info
ON lamisplus_client_database_info(table_name,column_name);
