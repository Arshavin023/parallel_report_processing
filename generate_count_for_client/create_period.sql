-- Table: expanded_radet.period

-- DROP TABLE IF EXISTS public.period;

CREATE TABLE IF NOT EXISTS public.period
(
    periodid character varying COLLATE pg_catalog."default",
    periodcode character varying COLLATE pg_catalog."default",
    table_name character varying COLLATE pg_catalog."default",
    is_active boolean,
    start_date date,
    date date,
    is_radet_available boolean DEFAULT false
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.period
    OWNER to lamisplus_etl;
-- DROP INDEX IF EXISTS expanded_radet.idx_expanddradet_period;

CREATE INDEX IF NOT EXISTS idx_expanddradet_period
    ON public.period USING btree
    (periodid COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;