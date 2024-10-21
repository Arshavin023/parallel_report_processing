-- FUNCTION: public.generate_weekly_count_ods_tables(text, text, text)

-- DROP FUNCTION IF EXISTS public.generate_weekly_count_ods_tables(text, text, text);

CREATE OR REPLACE FUNCTION public.generate_weekly_count_ods_tables(
	ods_table_name text,
	frontend_table_name text,
	constraint_column text)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    ods_table TEXT;
	load_time timestamp;
	period_start date;
	period_end_date date;
	period_end date;
	
	period_text character varying;

BEGIN
	
	SELECT CAST('1980-01-01' AS DATE) 
	INTO period_start;
	
	SELECT date 
	INTO period_end_date
	FROM public.period WHERE is_active;
	
-- 	end date of current period didn't work
-- 	SELECT date + INTERVAL '2 day' AS date 
-- 	INTO period_end
-- 	FROM expanded_radet.period WHERE is_active
	
	SELECT periodcode 
	INTO period_text
	FROM public.period WHERE is_active;

-- 	SELECT TIMEOFDAY() INTO load_time;
	
    EXECUTE FORMAT(
	'INSERT INTO public.ods_count_monitoring(
	table_name,period,period_end_date,current_total_records)
	SELECT %L table_name,%L period,	CAST(%L AS DATE) period_end, COUNT(DISTINCT %s) AS current_total_records
	FROM %s t1
	GROUP BY 1,2,3',
		frontend_table_name,period_text,period_end_date,constraint_column,
		ods_table_name);

	-- Print the ods_table_name
    RAISE NOTICE 'datim aggregated count for % successfully inserted', ods_table_name;
		
    -- Commit transaction for the current lab test
    PERFORM pg_advisory_xact_lock(hashtext(ods_table_name));
END;
$BODY$;

ALTER FUNCTION public.generate_weekly_count_ods_tables(text, text, text)
    OWNER TO lamisplus_etl;