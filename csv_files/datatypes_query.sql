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
    table_name ASC;
