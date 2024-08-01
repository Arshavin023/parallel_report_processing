# lamisplus_sync_htsprep_datamart
`hts_prep_datamart_pipeline.py` This Python script is the main component of the data pipeline. It interacts with the database, executes SQL queries, and manages the flow of data from the staging layer to the final datamart. The script follows a structured approach to extract data from the staging layer, transform it according to business logic, and load it into the final datamart tables.

## Description

This repository contains a data pipeline script written in Python along with supporting Bash scripts. The data pipeline is responsible for extracting, transforming, and loading data from various sources into a data mart for HIV testing and pre-exposure prophylaxis (PrEP) related data. The pipeline is divided into several parts, including initializing database connection and logging, building a staging layer, preparing data for the final datamart, and executing the main pipeline.

## Installation

1. Clone the repository.

``` 
git clone https://github.com/Data-Fi-Nigeria-LAMISPlus/lamisplus_sync_htsprep_datamart.git
```

2. Install the required dependencies using 

```
pip install -r requirements.txt
```

3. Set up the database configurations in `config.py`.

## Dependencies
- Python 3
- PostgreSQL database
- psycopg2 library for Python (to interact with PostgreSQL)


## Usage

1. Make sure the database servers are running.
2. Run the run_pipeline.sh Bash script to start the pipeline.
3. Install the required Python dependencies (psycopg2).
4. Monitor the console output and process logs for any errors or status updates.

## Code Explanation

The provided Python script (`hts_prep_datamart_pipeline.py`) performs the following tasks:

- **Database Connection**: It establishes connections to source and destination databases using psycopg2.

- **Table Operations**: It defines functions to get table columns, execute queries, insert into a process log, and update process log.

- **Data Mart Building Process**: The `run_build_staging_layer()` function iterates through a list of tables, drops them if they exist, and then creates them in the destination database as replicas of the corresponding tables in the source database.
This function initializes the staging layer by creating the required tables and schema in the database. It executes SQL commands to create tables for storing raw data from different sources.

- **Data Preparation Processes**: There are several functions like `run_prepare_hts_client()`, `run_prepare_patient_person()`, and `run_hts_helpers()` which perform specific data preparation tasks including dropping tables, creating tables, and populating them with data from the source database.

- **Index Creation**: The `run_create_indexes()` function creates indexes on certain columns of the created tables to optimize query performance.

- **Final HTS Data Mart Preparation**: The `run_prepare_final_htsquery_datamart()` function seems to create a final table named `final_htsquery_datamart_temp` by joining data from multiple tables and applying certain transformations.

- **Final PREP Data Mart Preparation**: The `run_prepare_final_prepquery_datamart()` function seems to create a final table named `final_prepquery_datamart_temp` by joining data from multiple tables and applying certain transformations. This function prepares the data for the final datamart by transforming and aggregating the raw data from the staging layer. It executes complex SQL queries to join multiple tables, perform calculations, and extract relevant information for analysis.

- **Swipe final tables**: This quickly drops the old final hts and prep datamarts and then renames the temp tables to have the same names as the finals. 

- **Bash Script Process Run**: This Bash script is responsible for starting the main pipeline `run_pipeline.sh`. It first checks if the pipeline is already running using the pgrep command. If not, it starts the Python script hts_prep_datamart_pipeline.py which orchestrates the entire ETL process.

## Automation

Pipeline has been automated using the `crontab` functionality on linux

See support codes below

```
sudo crontab -e {edits crontab}

0 2 * * * /home/oluwaloseyi/lamisplus_sync_htsprep_datamart/hts_prep_datamart_pipeline.py >> /home/oluwaloseyi/lamisplus_sync_htsprep_datamart/hts_prep_datamartlog.log 2>&1  {pipeline scheduled to run at 2am everyday}

sudo crontab -l {see available crontabs schedules}

```

## Monitoring

For monitoring, use process logs in the hts_prep_datamart schema. See code below:

```
select * from hts_prep_datamart.hts_process_log
where date_trunc('day', start_time) = '<date_of_run>'
```

## Credits

Include credits here if applicable.

