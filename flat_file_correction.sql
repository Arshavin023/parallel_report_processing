select * from public.central_data_element limit 6

update public.central_data_element
set run = true
where id =6

select * from public.central_data_element where run

create table public.aggregate_flatfile_01082024_version2 as
select * from public.aggregate_flatfile

truncate public.aggregate_flatfile;

create table public.aggregate_flatfile_01082024 as
select count(*) from public.aggregate_flatfile_01082024

delete from public.aggregate_flatfile --limit 5
where data_element_name = 'TX_ML (N, DSD, Age/Sex/ARTCauseofDeath/HIVStatus): On ART no clinical contact'

create table public.central_category_option_combo_01082024

insert into public.aggregate_flatfile
select * from public.aggregate_flatfile_01082024_version2