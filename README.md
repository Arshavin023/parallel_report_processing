# Airflow ETL/ELT DAGs
## Overview
This project automates high-volume data movement between production staging (Postgres) and the Data Warehouse (ODS). It focuses on idempotent ETL processes, utilizing Python-based multithreading to reduce latency and ensuring strict PII masking during the transfer protocol.

# Table of Contents
- [Introduction](#introduction)
- [Installation](#installation)
- [Database Credentials](#configuration)
- [Launch-Airflow-Web-UI](#testting)


## Introduction <a name="introduction"></a>
This following are Airflow DAGs and there respective functions
- lamisplus_stg_to_ods: Schedules and executes periodic ETL on different tables between staging database (lamisplus_staging_dwh on PRODUCTION FILE SERVER) and data warehouse (lamisplus_ods_dwh on PRODUCTION DATA WAREHOUSE SERVER)
- generate_weekly_reports_v2: Schedules and executes periodic report generation for different reports; RADET, HTS, PreP, PrEP_longitudinal, Family_Partner_Index, TB, AHD, PMTCT_HTS and Maternal_Cohort


## Installation <a name="installation"></a>

Clone the repository to your local machine:
``` 
git clone https://github.com/Data-Fi-Nigeria-LAMISPlus/lamisplus__sync_ods_pipelines.git
```

Navigate to the project directory:
``` 
cd lamisplus_sync_ods_pipeline
```

Kindly refer to the Airflow Installation Guide provided in the repository
- Install and get Airflow up and running

## Database_Credentials <a name="Database_Credentials"></a>
- Create database file '/home/lamisplus/database_credentials/config.ini'

## Launch-Airflow-Web-UI <a name="Launch Airflow Web UI"></a>

- Navigate to your browser and launch http://public-IP:port
- Login with Airflow credentials set during Airflow installation

## License <a name="license"></a>
- MIT License

## Authors & Acknowledgements <a name="authors_and_acknowledgments"></a>
- [Uche Nnodim](https://github.com/Arshavin023)
- [Emmanuel Nnajiofor](https://github.com/emmannajichi)
- [ChukwuEmeka Ilozie](https://github.com/Asquarep)
- [Peter Abiodun](https://github.com/drjavanew)
- [Barnabas Tyav](https://github.com/tyavbarnabas)
