# Airflow ETL/ELT DAGs
## Overview
This repository contains Python scripts automate data processing and migration from the lamisplus_staging_dwh (situated on the PRODUCTION FILE SERVER) database to the lamisplus_ods_dwh (situated on PRODUCTION DATA WAREHOUSE) database.

# Table of Contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Database Credentials](#configuration)
- [Launch-Airflow-Web-UI](#testting)


## Introduction <a name="introduction"></a>
This repository contains several Airflow DAGS that orchestration the following data pipelines
- stg_to_ods
- LamisPlus report generation; RADET, HTS, PreP, PMTCT_HTS and Maternal_Cohort
- Nomis report generation 
- Custom report generation i.e., laboratory_results, clinical_results, etc.

## Prerequisites <a name="prerequisites"></a>
Before cloning this report and installing Airflow, ensure the following prerequisites are installed on your virtual machine:

- Python 3.x
- PostgreSQL database
- virtualenv
- psycopg2 library (pip install psycopg2)
- pandas library (pip install pandas)
- sqlalchemy (pip install sqlalchemy)

## Installation <a name="installation"></a>
Kindly refer to the Airflow Installation Guide provided in this report
Clone the repository to your local machine:

``` 
git clone https://github.com/Data-Fi-Nigeria-LAMISPlus/lamisplus_sync_ods_pipeline.git
```

Navigate to the project directory:


``` 
cd lamisplus_sync_ods_pipeline
```

Install the required Python packages:

```
pip install -r requirements.txt
```

## Database_Credentials <a name="Database_Credentials"></a>
- Create database file '/home/lamisplus/database_credentials/config.ini'

## Launch-Airflow-Web-UI <a name="Launch Airflow Web UI"></a>

- Navigate to your browser and launch http://public-IP:port
- Login with Airflow credentials set during Airflow installation
