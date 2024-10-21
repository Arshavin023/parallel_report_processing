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
    OWNER to postgres;
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
    OWNER to postgres;
CREATE TABLE public."ods_count__2024Q3" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024Q3')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024Q3"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024Q4" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024Q4')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024Q4"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W1" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W1')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W1"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W10" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W10')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W10"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W11" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W11')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W11"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W12" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W12')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W12"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W13" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W13')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W13"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W14" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W14')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W14"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W15" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W15')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W15"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W16" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W16')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W16"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W17" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W17')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W17"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W18" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W18')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W18"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W19" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W19')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W19"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W2" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W2')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W2"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W20" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W20')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W20"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W21" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W21')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W21"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W22" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W22')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W22"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W23" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W23')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W23"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W24" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W24')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W24"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W25" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W25')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W25"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W26" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W26')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W26"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W27" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W27')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W27"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W28" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W28')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W28"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W29" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W29')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W29"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W3" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W3')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W3"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W30" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W30')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W30"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W31" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W31')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W31"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W32" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W32')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W32"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W33" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W33')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W33"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W34" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W34')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W34"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W35" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W35')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W35"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W36" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W36')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W36"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W37" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W37')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W37"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W38" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W38')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W38"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W39" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W39')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W39"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W4" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W4')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W4"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W40" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W40')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W40"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W41" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W41')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W41"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W42" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W42')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W42"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W43" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W43')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W43"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W44" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W44')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W44"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W45" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W45')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W45"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W46" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W46')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W46"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W47" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W47')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W47"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W48" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W48')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W48"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W49" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W49')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W49"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W5" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W5')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W5"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W50" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W50')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W50"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W51" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W51')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W51"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W52" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W52')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W52"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W6" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W6')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W6"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W7" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W7')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W7"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W8" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W8')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W8"
    OWNER to postgres;
CREATE TABLE public."ods_count__2024W9" PARTITION OF public.ods_count_monitoring
    FOR VALUES IN ('2024W9')
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."ods_count__2024W9"
    OWNER to postgres;


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
    OWNER to postgres;
-- Index: odstablename_ods_tables

-- DROP INDEX IF EXISTS public.odstablename_ods_tables;

CREATE INDEX IF NOT EXISTS odstablename_ods_tables
    ON public.ods_tables USING btree
    (ods_table_name COLLATE pg_catalog."C" ASC NULLS LAST)
    TABLESPACE pg_default;


INSERT INTO public.ods_tables VALUES ('base_organisation_unit', '(t1.id)', 'base_organisation_unit-(t1.id)');
INSERT INTO public.ods_tables VALUES ('base_application_codeset', '(t1.id)', 'base_application_codeset-(t1.id)');
INSERT INTO public.ods_tables VALUES ('base_organisation_unit_identifier', '(t1.id)', 'base_organisation_unit_identifier-(t1.id)');
INSERT INTO public.ods_tables VALUES ('biometric', '(t1.id)', 'biometric-(t1.id)');
INSERT INTO public.ods_tables VALUES ('case_manager', '(t1.id)', 'case_manager-(t1.id)');
INSERT INTO public.ods_tables VALUES ('case_manager_patients', '(t1.id)', 'case_manager_patients-(t1.id)');
INSERT INTO public.ods_tables VALUES ('dsd_devolvement', '(t1.id)', 'dsd_devolvement-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_art_clinical', '(t1.id)', 'hiv_art_clinical-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_art_pharmacy', '(t1.id)', 'hiv_art_pharmacy-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_art_pharmacy_regimens', '(t1.id)', 'hiv_art_pharmacy_regimens-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_eac', '(t1.id)', 'hiv_eac-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_eac_session', '(t1.id)', 'hiv_eac_session-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_enrollment', '(t1.id)', 'hiv_enrollment-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_observation', '(t1.id)', 'hiv_observation-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_regimen', '(t1.id)', 'hiv_regimen-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_regimen_type', '(t1.id)', 'hiv_regimen_type-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_regimen_resolver', '(t1.id)', 'hiv_regimen_resolver-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_status_tracker', '(t1.id)', 'hiv_status_tracker-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hts_client', '(t1.id)', 'hts_client-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hts_index_elicitation', '(t1.id)', 'hts_index_elicitation-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hts_risk_stratification', '(t1.id)', 'hts_risk_stratification-(t1.id)');
INSERT INTO public.ods_tables VALUES ('laboratory_labtest', '(t1.id)', 'laboratory_labtest-(t1.id)');
INSERT INTO public.ods_tables VALUES ('laboratory_test', '(t1.id)', 'laboratory_test-(t1.id)');
INSERT INTO public.ods_tables VALUES ('laboratory_order', '(t1.id)', 'laboratory_order-(t1.id)');
INSERT INTO public.ods_tables VALUES ('laboratory_result', '(t1.id)', 'laboratory_result-(t1.id)');
INSERT INTO public.ods_tables VALUES ('laboratory_sample', '(t1.id)', 'laboratory_sample-(t1.id)');
INSERT INTO public.ods_tables VALUES ('patient_encounter', '(t1.id)', 'patient_encounter-(t1.id)');
INSERT INTO public.ods_tables VALUES ('patient_person', '(t1.id)', 'patient_person-(t1.id)');
INSERT INTO public.ods_tables VALUES ('patient_visit', '(t1.id)', 'patient_visit-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_anc', '(t1.id)', 'pmtct_anc-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_delivery', '(t1.id)', 'pmtct_delivery-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_enrollment', '(t1.id)', 'pmtct_enrollment-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_infant_arv', '(t1.id)', 'pmtct_infant_arv-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_infant_information', '(t1.id)', 'pmtct_infant_information-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_infant_mother_art', '(t1.id)', 'pmtct_infant_mother_art-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_infant_pcr', '(t1.id)', 'pmtct_infant_pcr-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_infant_rapid_antibody', '(t1.id)', 'pmtct_infant_rapid_antibody-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_infant_visit', '(t1.id)', 'pmtct_infant_visit-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_mother_visitation', '(t1.id)', 'pmtct_mother_visitation-(t1.id)');
INSERT INTO public.ods_tables VALUES ('prep_clinic', '(t1.id)', 'prep_clinic-(t1.id)');
INSERT INTO public.ods_tables VALUES ('prep_eligibility', '(t1.id)', 'prep_eligibility-(t1.id)');
INSERT INTO public.ods_tables VALUES ('prep_enrollment', '(t1.id)', 'prep_enrollment-(t1.id)');
INSERT INTO public.ods_tables VALUES ('prep_interruption', '(t1.id)', 'prep_interruption-(t1.id)');
INSERT INTO public.ods_tables VALUES ('triage_vital_sign', '(t1.id)', 'triage_vital_sign-(t1.id)');


-- Table: public.period

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
    OWNER to postgres;
-- DROP INDEX IF EXISTS public.idx_expanddradet_period;

CREATE INDEX IF NOT EXISTS idx_expanddradet_period
    ON public.period USING btree
    (periodid COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
	

INSERT INTO public.period VALUES ('2024W13', '2024W13', 'expanded_radet_weekly_2024w13', false, '2024-03-24', '2024-03-30', true);
INSERT INTO public.period VALUES ('2024W35', '2024W35', 'expanded_radet_weekly_2024w35', false, '2024-08-25', '2024-08-31', true);
INSERT INTO public.period VALUES ('2024W32', '2024W32', 'expanded_radet_weekly_2024w32', false, '2024-08-04', '2024-08-10', true);
INSERT INTO public.period VALUES ('2024W36', '2024W36', 'expanded_radet_weekly_2024w36', false, '2024-09-01', '2024-09-07', true);
INSERT INTO public.period VALUES ('2024W31', '2024W31', 'expanded_radet_weekly_2024w31', false, '2024-07-28', '2024-08-03', true);
INSERT INTO public.period VALUES ('2024W30', '2024W30', 'expanded_radet_weekly_2024w30', false, '2024-07-21', '2024-07-27', true);
INSERT INTO public.period VALUES ('2024W29', '2024W29', 'expanded_radet_weekly_2024w29', false, '2024-07-14', '2024-07-20', true);
INSERT INTO public.period VALUES ('2024W28', '2024W28', 'expanded_radet_weekly_2024w28', false, '2024-07-07', '2024-07-13', true);
INSERT INTO public.period VALUES ('2024W27', '2024W27', 'expanded_radet_weekly_2024w27', false, '2024-06-30', '2024-07-06', true);
INSERT INTO public.period VALUES ('2024W26', '2024W26', 'expanded_radet_weekly_2024w26', false, '2024-06-23', '2024-06-29', true);
INSERT INTO public.period VALUES ('﻿2024W1', '2024W1', 'expanded_radet_weekly_﻿2024w1', false, '2023-12-31', '2024-01-06', false);
INSERT INTO public.period VALUES ('2024W2', '2024W2', 'expanded_radet_weekly_2024w2', false, '2024-01-07', '2024-01-13', false);
INSERT INTO public.period VALUES ('2024W21', '2024W21', 'expanded_radet_weekly_2024w21', false, '2024-05-19', '2024-05-25', false);
INSERT INTO public.period VALUES ('2024W3', '2024W3', 'expanded_radet_weekly_2024w3', false, '2024-01-14', '2024-01-20', false);
INSERT INTO public.period VALUES ('2024W4', '2024W4', 'expanded_radet_weekly_2024w4', false, '2024-01-21', '2024-01-27', false);
INSERT INTO public.period VALUES ('2024W5', '2024W5', 'expanded_radet_weekly_2024w5', false, '2024-01-28', '2024-02-03', false);
INSERT INTO public.period VALUES ('2024W6', '2024W6', 'expanded_radet_weekly_2024w6', false, '2024-02-04', '2024-02-10', false);
INSERT INTO public.period VALUES ('2024W7', '2024W7', 'expanded_radet_weekly_2024w7', false, '2024-02-11', '2024-02-17', false);
INSERT INTO public.period VALUES ('2024W8', '2024W8', 'expanded_radet_weekly_2024w8', false, '2024-02-18', '2024-02-24', false);
INSERT INTO public.period VALUES ('2024W9', '2024W9', 'expanded_radet_weekly_2024w9', false, '2024-02-25', '2024-03-02', false);
INSERT INTO public.period VALUES ('2024Q3', '2024Q3', 'final_radet_2024Q3', false, '2024-04-01', '2024-06-30', true);
INSERT INTO public.period VALUES ('2024W10', '2024W10', 'expanded_radet_weekly_2024w10', false, '2024-03-03', '2024-03-09', false);
INSERT INTO public.period VALUES ('2024W11', '2024W11', 'expanded_radet_weekly_2024w11', false, '2024-03-10', '2024-03-16', false);
INSERT INTO public.period VALUES ('2024W12', '2024W12', 'expanded_radet_weekly_2024w12', false, '2024-03-17', '2024-03-23', false);
INSERT INTO public.period VALUES ('2024W14', '2024W14', 'expanded_radet_weekly_2024w14', false, '2024-03-31', '2024-04-06', false);
INSERT INTO public.period VALUES ('2024W15', '2024W15', 'expanded_radet_weekly_2024w15', false, '2024-04-07', '2024-04-13', false);
INSERT INTO public.period VALUES ('2024W22', '2024W22', 'expanded_radet_weekly_2024w22', false, '2024-05-26', '2024-06-01', false);
INSERT INTO public.period VALUES ('2024W23', '2024W23', 'expanded_radet_weekly_2024w23', false, '2024-06-02', '2024-06-08', false);
INSERT INTO public.period VALUES ('2024W24', '2024W24', 'expanded_radet_weekly_2024w24', false, '2024-06-09', '2024-06-15', false);
INSERT INTO public.period VALUES ('2024W25', '2024W25', 'expanded_radet_weekly_2024w25', false, '2024-06-16', '2024-06-22', false);
INSERT INTO public.period VALUES ('2024W42', '2024W42', 'expanded_radet_weekly_2024w42', false, '2024-10-13', '2024-10-19', false);
INSERT INTO public.period VALUES ('2024W43', '2024W43', 'expanded_radet_weekly_2024w43', false, '2024-10-20', '2024-10-26', false);
INSERT INTO public.period VALUES ('2024W44', '2024W44', 'expanded_radet_weekly_2024w44', false, '2024-10-27', '2024-11-02', false);
INSERT INTO public.period VALUES ('2024W45', '2024W45', 'expanded_radet_weekly_2024w45', false, '2024-11-03', '2024-11-09', false);
INSERT INTO public.period VALUES ('2024W46', '2024W46', 'expanded_radet_weekly_2024w46', false, '2024-11-10', '2024-11-16', false);
INSERT INTO public.period VALUES ('2024W47', '2024W47', 'expanded_radet_weekly_2024w47', false, '2024-11-17', '2024-11-23', false);
INSERT INTO public.period VALUES ('2024W48', '2024W48', 'expanded_radet_weekly_2024w48', false, '2024-11-24', '2024-11-30', false);
INSERT INTO public.period VALUES ('2024W49', '2024W49', 'expanded_radet_weekly_2024w49', false, '2024-12-01', '2024-12-07', false);
INSERT INTO public.period VALUES ('2024W50', '2024W50', 'expanded_radet_weekly_2024w50', false, '2024-12-08', '2024-12-14', false);
INSERT INTO public.period VALUES ('2024W51', '2024W51', 'expanded_radet_weekly_2024w51', false, '2024-12-15', '2024-12-21', false);
INSERT INTO public.period VALUES ('2024W52', '2024W52', 'expanded_radet_weekly_2024w52', false, '2024-12-22', '2024-12-28', false);
INSERT INTO public.period VALUES ('2024W18', '2024W18', 'expanded_radet_weekly_2024w18', false, '2024-04-28', '2024-05-04', false);
INSERT INTO public.period VALUES ('2024W17', '2024W17', 'expanded_radet_weekly_2024w17', false, '2024-04-21', '2024-04-27', false);
INSERT INTO public.period VALUES ('2024W16', '2024W16', 'expanded_radet_weekly_2024w16', false, '2024-04-14', '2024-04-20', false);
INSERT INTO public.period VALUES ('2024W19', '2024W19', 'expanded_radet_weekly_2024w19', false, '2024-05-05', '2024-05-11', false);
INSERT INTO public.period VALUES ('2024W20', '2024W20', 'expanded_radet_weekly_2024w20', false, '2024-05-12', '2024-05-18', false);
INSERT INTO public.period VALUES ('2024Q2', '2024Q2', 'final_radet_quartely_2024Q2', false, '2024-01-01', '2024-03-31', false);
INSERT INTO public.period VALUES ('2024W34', '2024W34', 'expanded_radet_weekly_2024w34', false, '2024-08-18', '2024-08-24', true);
INSERT INTO public.period VALUES ('2024W33', '2024W33', 'expanded_radet_weekly_2024w33', false, '2024-08-11', '2024-08-17', true);
INSERT INTO public.period VALUES ('2024W38', '2024W38', 'expanded_radet_weekly_2024w38', false, '2024-09-15', '2024-09-21', true);
INSERT INTO public.period VALUES ('2024W37', '2024W37', 'expanded_radet_weekly_2024w37', false, '2024-09-08', '2024-09-14', false);
INSERT INTO public.period VALUES ('2024W40', '2024W40', 'expanded_radet_weekly_2024w40', false, '2024-09-29', '2024-10-05', true);
INSERT INTO public.period VALUES ('2024Q4', '2024Q4', 'final_radet_2024Q4', false, '2024-07-01', '2024-09-30', true);
INSERT INTO public.period VALUES ('2024W39', '2024W39', 'expanded_radet_weekly_2024w39', false, '2024-09-22', '2024-09-28', true);
INSERT INTO public.period VALUES ('2024W41', '2024W41', 'expanded_radet_weekly_2024w41', true, '2024-10-06', '2024-10-12', true);


-- FUNCTION: public.generate_weekly_count_ods_tables(text, text, text)

-- DROP FUNCTION IF EXISTS public.generate_weekly_count_ods_tables(text, text, text);

CREATE OR REPLACE FUNCTION public.generate_weekly_count_ods_tables(
	ods_table_name text,
	frontend_table_name text,
	constraint_column text)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    ods_table TEXT;
	load_time timestamp;
	period_start date;
	period_end_date date;
	period_end date;
	
	period_text character varying;

BEGIN
	
	SELECT CAST('1980-01-01' AS DATE) 
	INTO period_start;
	
	SELECT date 
	INTO period_end_date
	FROM public.period WHERE is_active;
	
-- 	end date of current period didn't work
-- 	SELECT date + INTERVAL '2 day' AS date 
-- 	INTO period_end
-- 	FROM expanded_radet.period WHERE is_active
	
	SELECT periodcode 
	INTO period_text
	FROM public.period WHERE is_active;

-- 	SELECT TIMEOFDAY() INTO load_time;
	
    EXECUTE FORMAT(
	'INSERT INTO public.ods_count_monitoring(
	table_name,period,period_end_date,current_total_records)
	SELECT %L table_name,%L period,	CAST(%L AS DATE) period_end, COUNT(DISTINCT %s) AS current_total_records
	FROM %s t1
	GROUP BY 1,2,3',
		frontend_table_name,period_text,period_end_date,constraint_column,
		ods_table_name);

	-- Print the ods_table_name
    RAISE NOTICE 'datim aggregated count for % successfully inserted', ods_table_name;
		
    -- Commit transaction for the current lab test
    PERFORM pg_advisory_xact_lock(hashtext(ods_table_name));
END;
$BODY$;

ALTER FUNCTION public.generate_weekly_count_ods_tables(text, text, text)
    OWNER TO postgres;


-- PROCEDURE: public.proc_loop_through_ods_tables()

-- DROP PROCEDURE IF EXISTS public.proc_loop_through_ods_tables();

CREATE OR REPLACE PROCEDURE public.proc_loop_through_ods_tables(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    inputs text[];
    input text;
    frontend_table_name text;
	constraint_column text;
	ods_table text;
	
BEGIN
    -- Populate the array with values from the existing table
    SELECT array_agg(ods_table_info)
    INTO inputs
    FROM public.ods_tables
	WHERE ods_table_name 
	NOT IN ('pmtct_infant_rapid_antibody',
		'hiv_regimen_resolver');
	
	-- Populate the array with value from the existing test table
-- 	SELECT array_agg(ods_table_info)
--     INTO inputs
-- 	FROM public.test_ods_tables;

    -- Loop through each input value and execute the dynamic query
    FOREACH input IN ARRAY inputs
    LOOP
        frontend_table_name := REPLACE(split_part(input, '-', 1),'ods_','');
		ods_table := split_part(input, '-', 1);
		constraint_column := split_part(input, '-', 2);

        -- Call the function to process each lab test
        PERFORM public.generate_weekly_count_ods_tables(ods_table,frontend_table_name,
														constraint_column);

    END LOOP;
END;
$BODY$;
ALTER PROCEDURE public.proc_loop_through_ods_tables()
    OWNER TO postgres;


--Generate summary report
TRUNCATE public.ods_count_monitoring;
CALL public.proc_loop_through_ods_tables();
