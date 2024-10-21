--
-- PostgreSQL database dump
--

-- Dumped from database version 14.13 (Ubuntu 14.13-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 16.1

-- Started on 2024-10-18 09:37:47

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4873 (class 0 OID 24627)
-- Dependencies: 327
-- Data for Name: period; Type: TABLE DATA; Schema: expanded_radet; Owner: -
--

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


-- Completed on 2024-10-18 09:37:54

--
-- PostgreSQL database dump complete
--

