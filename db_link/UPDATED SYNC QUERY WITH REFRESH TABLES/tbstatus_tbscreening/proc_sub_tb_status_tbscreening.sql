--
-- Name: proc_sub_date_current_clinical(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE OR REPLACE PROCEDURE expanded_radet.proc_sub_tb_status_tbscreening()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.sub_tb_status_tbscreening_new;
CREATE TABLE expanded_radet.sub_tb_status_tbscreening_new AS
SELECT * , 
ROW_NUMBER() OVER (PARTITION BY person_uuid, ods_datim_id ORDER BY dateOfTbScreened DESC) AS rowNums 
FROM expanded_radet.tbstatus_tbscreening
WHERE dateoftbscreened between '1980-01-01' 
and (select date from expanded_radet.period where is_active) -----?3
;

drop table if exists expanded_radet.sub_tb_status_tbscreening;
alter table expanded_radet.sub_tb_status_tbscreening_new rename to sub_tb_status_tbscreening;

CREATE INDEX idx_row_number_cte_sub_tb_status_tbscreening
ON expanded_radet.sub_tb_status_tbscreening (rowNums);

SELECT TIMEOFDAY() INTO end_time;

INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('sub_tb_status_tbscreening', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_sub_tb_status_tbscreening() OWNER TO lamisplus_etl;

--call expanded_radet.proc_sub_tb_status_tbscreening()