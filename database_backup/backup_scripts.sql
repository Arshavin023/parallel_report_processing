--Database backups
pg_dump -h localhost -p 5432 -U lamisplus_etl -d lamisplus_ods_dwh --schema-only > lamisplus_ods_dwh_schema_20241016.sql
pg_dump -h localhost -p 5432 -U lamisplus_etl -d radet --schema-only > radet_schema_20241016.sql
pg_dump -h localhost -p 5432 -U lamisplus_etl -d hts_prep --schema-only > hts_prep_schema_20241016.sql
pg_dump -h localhost -p 5432 -U lamisplus_etl -d pmtct --schema-only > pmtct_database_schema_20241016.sql

QUWeIQvD27BYei1