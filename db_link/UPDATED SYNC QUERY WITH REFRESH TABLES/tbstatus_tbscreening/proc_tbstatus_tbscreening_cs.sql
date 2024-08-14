--
-- Name: proc_sub_date_current_clinical(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE OR REPLACE PROCEDURE expanded_radet.proc_tbstatus_tbscreening_cs()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_tbstatus_tbscreening_cs_new;
CREATE TABLE expanded_radet.cte_tbstatus_tbscreening_cs_new AS
SELECT * FROM expanded_radet.sub_tb_status_tbscreening WHERE rowNums=1
;

drop table if exists expanded_radet.cte_tbstatus_tbscreening_cs;
alter table expanded_radet.cte_tbstatus_tbscreening_cs_new rename to cte_tbstatus_tbscreening_cs;

CREATE INDEX idx_personuuid_datimid_cte_tbstatus_tbscreening_cs
ON expanded_radet.cte_tbstatus_tbscreening_cs (person_uuid,ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;

INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_tbstatus_tbscreening_cs', start_time,end_time);
END
$$;

ALTER PROCEDURE expanded_radet.proc_sub_tb_status_tbscreening() OWNER TO lamisplus_etl;

--call expanded_radet.proc_tbstatus_tbscreening_cs()