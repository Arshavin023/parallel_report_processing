#!/bin/bash

# Calculate a timestamp 30 days ago
CLEAN_DATE=$(date -d "30 days ago" "+%Y-%m-%d")

# Run the cleanup command with the calculated date
/home/lamisplus/airflow/airflow_env/bin/airflow db clean --clean-before-timestamp "$CLEAN_DATE" --yes
