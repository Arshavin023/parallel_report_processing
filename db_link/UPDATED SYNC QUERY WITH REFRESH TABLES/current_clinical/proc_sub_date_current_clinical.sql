--
-- Name: proc_sub_date_current_clinical(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_sub_date_current_clinical()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_sub_date_current_clinical_new;
CREATE TABLE expanded_radet.cte_sub_date_current_clinical_new AS
SELECT * 
FROM expanded_radet.cte_sub_sub_date_current_clinical
WHERE max_rownum=1;

drop table if exists expanded_radet.cte_sub_date_current_clinical;
alter table expanded_radet.cte_sub_date_current_clinical_new rename to cte_sub_date_current_clinical;

drop index if exists idx_datecurrentclinical_maxdatepersonuuidodsdatimid;
CREATE INDEX idx_datecurrentclinical_maxdatepersonuuidodsdatimid
ON expanded_radet.cte_sub_date_current_clinical (MAXDATE, person_uuid, ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;

INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_sub_date_current_clinical', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_sub_date_current_clinical() OWNER TO lamisplus_etl;
