-- PROCEDURE: public.proc_stream_patient_person_v2(character varying)

-- DROP PROCEDURE IF EXISTS public.proc_stream_patient_person_v2(character varying);

CREATE OR REPLACE PROCEDURE public.proc_stream_patient_person_v2(
	IN table_name character varying)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    deleted_count bigint;
    stream_file_names text;  -- To hold comma-separated filenames
    quoted_file_names text;  -- To hold filenames with quotes for the IN clause
	quoted_file_names_dml text; -- To hold filenames with quotes for the IN clause for dml
    inserted_count bigint;
    size_before_deletion text;
    size_after_deletion text;

BEGIN
    -- Get the current start time
    SELECT TIMEOFDAY() INTO start_time;
    
    -- Get size of table in megabytes before deletion
    EXECUTE format('SELECT * FROM dblink(''db_link_staging'',
				   ''SELECT pg_size_pretty(pg_total_relation_size(table_schema || ''''.'''' || table_name)::bigint)
                FROM information_schema.tables WHERE table_schema = ''''public'''' AND table_name = ''''%s''''
				   '') AS sm(size text)', table_name)
    INTO size_before_deletion;

    -- Retrieve multiple file names from stg_monitoring into a comma-separated string
    EXECUTE format('SELECT string_agg(file_name, '','') 
                    FROM dblink(''db_link_staging'', 
                    ''SELECT file_name FROM stg_monitoring WHERE processed = ''''N'''' 
				   AND table_name = ''''%s'''' 
				   '') 
                    AS sm(file_name text)', table_name)
    INTO stream_file_names;

    -- If no filenames are found, exit the procedure
    IF stream_file_names IS NULL THEN
        RAISE NOTICE 'No unprocessed files found for table %', table_name;
        RETURN;
    END IF;

--     -- Properly quote each filename for the IN clause
	-- Properly quote each filename for the IN clause using quote_literal
    SELECT string_agg(quote_literal(file_name), ',')
    INTO quoted_file_names_dml
    FROM regexp_split_to_table(stream_file_names, ',') AS file_name;
	
-- Concatenate results from above
   SELECT string_agg('''' || quote_literal(file_name) || '''', ',')
	INTO quoted_file_names
	FROM regexp_split_to_table(stream_file_names, ',') AS file_name;
	
    -- Use the retrieved and quoted file names in the WHERE clause with IN
    EXECUTE format('INSERT INTO ods_patient_person(uuid, id, created_date, created_by, 
				   last_modified_date,last_modified_by, active, contact_point, address, gender, 
				   identifier, deceased, deceased_date_time, marital_status, employment_status, 
				   education, organization, 
                    contact, date_of_birth, date_of_registration, archived, facility_id,
                    nin_number, emr_id, first_name, sex, surname, other_name, hospital_number, 
                    is_date_of_birth_estimated, full_name, case_manager_id,ods_load_time, 
                    ods_datim_id, reason, latitude, longitude, source)
                    SELECT * FROM dblink(''db_link_staging'',
                    ''SELECT DISTINCT ON (uuid, ods_datim_id) uuid, id, created_date, created_by, last_modified_date, 
				     last_modified_by, 
                    active, contact_point, address, gender, identifier, deceased, 
                    deceased_date_time, marital_status, employment_status, education, organization, 
                    contact, date_of_birth, date_of_registration, archived, facility_id, 
                    nin_number, emr_id, first_name, sex, surname, other_name, hospital_number, 
                    is_date_of_birth_estimated, full_name, case_manager_id, stg_load_time ods_load_time, 
                    stg_datim_id ods_datim_id, reason, latitude, longitude, source
                    FROM %I pp
                    WHERE stg_file_name IN (%s)
				   '') 
                    AS sm(uuid character varying,id bigint,created_date timestamp without time zone,
				   		created_by character varying,
                        last_modified_date timestamp,last_modified_by character varying,
                        active boolean, contact_point jsonb,address jsonb,
                        gender jsonb,identifier jsonb,deceased boolean,
                        deceased_date_time timestamp,marital_status jsonb,
                        employment_status jsonb,education jsonb,
                        organization jsonb, contact jsonb,
                        date_of_birth date,
                        date_of_registration date,
                        archived integer,
                        facility_id bigint,
                        nin_number character varying,
                        emr_id character varying,
                        first_name character varying,
                        sex character varying,
                        surname character varying,
                        other_name character varying,
                        hospital_number character varying,
                        is_date_of_birth_estimated boolean,
                        full_name character varying,
                        case_manager_id bigint,
                        ods_load_time timestamp without time zone,
                        ods_datim_id character varying(255),
                        reason text,
                        latitude character varying,
                        longitude character varying,
                        source character varying)
				   
				   ON CONFLICT(uuid,ods_datim_id)
				   DO UPDATE SET
					id=EXCLUDED.id,	created_date=EXCLUDED.created_date,
					created_by=EXCLUDED.created_by,	last_modified_date=EXCLUDED.last_modified_date,
					last_modified_by=EXCLUDED.last_modified_by,
					active=EXCLUDED.active, contact_point=EXCLUDED.contact_point,
				    address=EXCLUDED.address, gender=EXCLUDED.gender,
				   	identifier=EXCLUDED.identifier,	deceased=EXCLUDED.deceased,
				    deceased_date_time=EXCLUDED.deceased_date_time, marital_status=EXCLUDED.marital_status,
				    employment_status=EXCLUDED.employment_status, education=EXCLUDED.education,
				    organization=EXCLUDED.organization, contact=EXCLUDED.contact,
				    date_of_birth=EXCLUDED.date_of_birth,date_of_registration=EXCLUDED.date_of_registration,
				    archived=EXCLUDED.archived,facility_id=EXCLUDED.facility_id,nin_number=EXCLUDED.nin_number,
				    emr_id=EXCLUDED.emr_id,first_name=EXCLUDED.first_name, sex=EXCLUDED.sex,
				    surname=EXCLUDED.surname,
				    other_name=EXCLUDED.other_name,
				    hospital_number=EXCLUDED.hospital_number,
				    is_date_of_birth_estimated=EXCLUDED.is_date_of_birth_estimated,
				    full_name=EXCLUDED.full_name,
				    case_manager_id=EXCLUDED.case_manager_id,
				    ods_load_time=EXCLUDED.ods_load_time,
				    reason=EXCLUDED.reason,
				    latitude=EXCLUDED.latitude,
				    longitude=EXCLUDED.longitude,
				    source=EXCLUDED.source',
				   table_name, quoted_file_names);
	
	-- Execute dynamic SQL to update processed column stg_monitoring for records inserted from the stg tables to ods_tables
	PERFORM dblink(
			'db_link_staging',
			  format('UPDATE stg_monitoring
					SET processed = ''Y'', stg_deleted=''N''
					WHERE processed = ''N'' AND table_name = ''stg_patient_person''
					AND file_name IN (%s)
					 ',quoted_file_names_dml)
					 );

	
	-- Execute dynamic SQL to delete records from tables that has moved to data warehouse

		PERFORM dblink(
		'db_link_staging',
			  format('
					DELETE FROM stg_patient_person pp
					WHERE stg_file_name IN (%s)',
					 quoted_file_names_dml)
				 );
				 
					
	-- Execute dynamic SQL to update stg_deleted column on stg_monitoring for records deleted from the stg tables
	
		PERFORM dblink(
		'db_link_staging',
			  format('
					UPDATE stg_monitoring
					SET stg_deleted =''Y'', error_message=''No errors''
					WHERE processed = ''Y'' 
					AND table_name = ''stg_patient_person''
					AND stg_deleted != ''Y''
					AND file_name IN (%s)',
					 quoted_file_names_dml)
				 );

    -- Get size of table in megabytes after deletion
     EXECUTE format('SELECT * FROM dblink(''db_link_staging'',
				   ''SELECT pg_size_pretty(pg_total_relation_size(table_schema || ''''.'''' || table_name)::bigint)
                FROM information_schema.tables WHERE table_schema = ''''public'''' AND table_name = ''''%s''''
				   '') AS sm(size text)', table_name)
    INTO size_after_deletion;

    -- Get the current end time
    SELECT TIMEOFDAY() INTO end_time;

    -- Log the streaming activity
    INSERT INTO public.ods_records_streaming_log (table_name, start_time, end_time, size_before_deletion, size_after_deletion) 
    VALUES (table_name, start_time, end_time, size_before_deletion, size_after_deletion);

END;
$BODY$;
ALTER PROCEDURE public.proc_stream_patient_person_v2(character varying)
    OWNER TO lamisplus_etl;
 
-- -- truncate ods_records_streaming_log;

-- CALL public.proc_stream_patient_person_v2('stg_patient_person');

-- SELECT * FROM ods_records_streaming_log;
