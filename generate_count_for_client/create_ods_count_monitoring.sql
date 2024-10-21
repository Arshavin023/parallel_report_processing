-- Table: public.ods_count_monitoring

DROP TABLE IF EXISTS public.ods_count_monitoring;

CREATE TABLE IF NOT EXISTS public.ods_count_monitoring
(
    table_name character varying COLLATE pg_catalog."default",
    period character varying COLLATE pg_catalog."default",
    period_end_date date,
    current_total_records bigint
) PARTITION BY LIST (period);

ALTER TABLE IF EXISTS public.ods_count_monitoring
    OWNER to lamisplus_etl;
-- Index: odsdatimidloadtime_ods_count_monitoring

-- DROP INDEX IF EXISTS public.odsdatimidloadtime_ods_count_monitoring;

CREATE INDEX IF NOT EXISTS odsdatimidloadtime_ods_count_monitoring
    ON public.ods_count_monitoring USING btree
    (period_end_date ASC NULLS LAST)
;

-- Partitions SQL

CREATE TABLE public."ods_count__2024Q2" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024Q2')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024Q2"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024Q3" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024Q3')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024Q3"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024Q4" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024Q4')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024Q4"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W1" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W1')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W1"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W10" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W10')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W10"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W11" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W11')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W11"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W12" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W12')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W12"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W13" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W13')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W13"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W14" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W14')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W14"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W15" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W15')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W15"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W16" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W16')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W16"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W17" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W17')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W17"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W18" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W18')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W18"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W19" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W19')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W19"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W2" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W2')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W2"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W20" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W20')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W20"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W21" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W21')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W21"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W22" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W22')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W22"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W23" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W23')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W23"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W24" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W24')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W24"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W25" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W25')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W25"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W26" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W26')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W26"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W27" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W27')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W27"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W28" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W28')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W28"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W29" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W29')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W29"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W3" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W3')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W3"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W30" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W30')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W30"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W31" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W31')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W31"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W32" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W32')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W32"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W33" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W33')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W33"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W34" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W34')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W34"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W35" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W35')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W35"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W36" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W36')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W36"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W37" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W37')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W37"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W38" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W38')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W38"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W39" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W39')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W39"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W4" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W4')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W4"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W40" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W40')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W40"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W41" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W41')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W41"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W42" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W42')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W42"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W43" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W43')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W43"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W44" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W44')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W44"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W45" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W45')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W45"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W46" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W46')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W46"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W47" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W47')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W47"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W48" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W48')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W48"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W49" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W49')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W49"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W5" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W5')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W5"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W50" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W50')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W50"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W51" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W51')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W51"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W52" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W52')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W52"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W6" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W6')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W6"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W7" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W7')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W7"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W8" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W8')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W8"
    OWNER to lamisplus_etl;
CREATE TABLE public."ods_count__2024W9" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W9')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W9"
    OWNER to lamisplus_etl;