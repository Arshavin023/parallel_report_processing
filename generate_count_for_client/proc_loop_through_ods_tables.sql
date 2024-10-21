-- PROCEDURE: public.proc_loop_through_ods_tables()

-- DROP PROCEDURE IF EXISTS public.proc_loop_through_ods_tables();

CREATE OR REPLACE PROCEDURE public.proc_loop_through_ods_tables(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    inputs text[];
    input text;
    frontend_table_name text;
	constraint_column text;
	ods_table text;
	
BEGIN
    -- Populate the array with values from the existing table
    SELECT array_agg(ods_table_info)
    INTO inputs
    FROM public.ods_tables
	WHERE ods_table_name 
	NOT IN ('pmtct_infant_rapid_antibody',
		'hiv_regimen_resolver');
	
	-- Populate the array with value from the existing test table
-- 	SELECT array_agg(ods_table_info)
--     INTO inputs
-- 	FROM public.test_ods_tables;

    -- Loop through each input value and execute the dynamic query
    FOREACH input IN ARRAY inputs
    LOOP
        frontend_table_name := REPLACE(split_part(input, '-', 1),'ods_','');
		ods_table := split_part(input, '-', 1);
		constraint_column := split_part(input, '-', 2);

        -- Call the function to process each lab test
        PERFORM public.generate_weekly_count_ods_tables(ods_table,frontend_table_name,
														constraint_column);

    END LOOP;
END;
$BODY$;
ALTER PROCEDURE public.proc_loop_through_ods_tables()
    OWNER TO lamisplus_etl;
