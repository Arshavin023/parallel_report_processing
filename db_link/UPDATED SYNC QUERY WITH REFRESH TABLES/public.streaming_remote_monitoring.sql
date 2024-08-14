-- Table: public.streaming_remote_monitoring

-- DROP TABLE IF EXISTS public.streaming_remote_monitoring;

CREATE TABLE IF NOT EXISTS public.streaming_remote_monitoring
(
    table_name character varying(100) COLLATE pg_catalog."default",
    record_count bigint,
    start_time timestamp without time zone,
    end_time timestamp without time zone
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.streaming_remote_monitoring
    OWNER to lamisplus_etl;