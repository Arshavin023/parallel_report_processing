CREATE OR REPLACE PROCEDURE public.proc_oda_load_time_index_creation()
    LANGUAGE plpgsql
    AS $_$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;
CREATE INDEX IF NOT EXISTS idx_streaming_remote_monitoring_tablename
ON public.streaming_remote_monitoring(table_name);
CREATE INDEX IF NOT EXISTS idx_streaming_remote_monitoring_endtime 
ON public.streaming_remote_monitoring(end_time);
CREATE INDEX IF NOT EXISTS brin_idx_ods_biometric_odsloadtime 
ON public.ods_biometric USING brin (ods_load_time);
CREATE INDEX IF NOT EXISTS brin_idx_ods_patient_person_odsloadtime 
ON public.ods_patient_person USING brin (ods_load_time);
CREATE INDEX IF NOT EXISTS brin_idx_ods_hiv_art_clinical_odsloadtime 
ON public.ods_hiv_art_clinical USING brin (ods_load_time);
CREATE INDEX IF NOT EXISTS brin_idx_ods_hiv_observation_odsloadtime 
ON public.ods_hiv_observation USING brin (ods_load_time);
CREATE INDEX IF NOT EXISTS brin_idx_ods_laboratory_test_odsloadtime 
ON public.ods_biometric USING brin (ods_load_time);
CREATE INDEX IF NOT EXISTS brin_idx_ods_hiv_art_pharmacy_odsloadtime 
ON public.ods_hiv_art_pharmacy USING brin (ods_load_time);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO public.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('patient_oda_load_time_index_creation', start_time,end_time);

END
$_$;

ALTER PROCEDURE public.proc_oda_load_time_index_creation() OWNER TO lamisplus_etl;

--call public.proc_oda_load_time_index_creation()
