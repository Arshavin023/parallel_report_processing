# Airflow ETL/ELT DAGs
## Overview
This project contains Airflow DAGS that automates extraction, transformation and loading of data between servers, and report generation Python Scripts for several Health Informatics reports.

# Table of Contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Database Credentials](#configuration)
- [Launch-Airflow-Web-UI](#testting)


## Introduction <a name="introduction"></a>
This following are Airflow DAGs and there respective functions
- lamisplus_stg_to_ods: Schedules and executes periodic ETL on different tables between staging database (lamisplus_staging_dwh on PRODUCTION FILE SERVER) and data warehouse (lamisplus_ods_dwh on PRODUCTION DATA WAREHOUSE SERVER)
- generate_weekly_reports: Schedules and executes periodic report generation for different reports; RADET, HTS, PreP, PrEP_longitudinal, Family_Partner_Index, TB, AHD, PMTCT_HTS and Maternal_Cohort
- Nomis report generation: Schedules and executes periodic report generation for different reports; NOMIS Child Monitor, 


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
