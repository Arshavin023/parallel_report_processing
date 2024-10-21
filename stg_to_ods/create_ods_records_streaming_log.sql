CREATE SEQUENCE ods_records_streaming_log_id_seq;
CREATE TABLE IF NOT EXISTS public.ods_records_streaming_log
(
    id bigint NOT NULL DEFAULT nextval('ods_records_streaming_log_id_seq'::regclass),
    table_name character varying(255) COLLATE pg_catalog."default",
    deleted_records_count bigint,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    size_before_deletion text COLLATE pg_catalog."default",
    size_after_deletion text COLLATE pg_catalog."default",
    CONSTRAINT ods_records_streaming_log_pkey PRIMARY KEY (id)
)