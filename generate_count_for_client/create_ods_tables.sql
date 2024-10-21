-- Table: public.ods_tables

-- DROP TABLE IF EXISTS public.ods_tables;

CREATE TABLE IF NOT EXISTS public.ods_tables
(
    ods_table_name text COLLATE pg_catalog."C",
    constraints_columns character varying COLLATE pg_catalog."default",
    ods_table_info character varying COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.ods_tables
    OWNER to lamisplus_etl;
-- Index: odstablename_ods_tables

-- DROP INDEX IF EXISTS public.odstablename_ods_tables;

CREATE INDEX IF NOT EXISTS odstablename_ods_tables
    ON public.ods_tables USING btree
    (ods_table_name COLLATE pg_catalog."C" ASC NULLS LAST)
    TABLESPACE pg_default;