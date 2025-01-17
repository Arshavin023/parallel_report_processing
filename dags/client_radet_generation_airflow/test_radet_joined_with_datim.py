from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.utils.task_group import TaskGroup
import datetime

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 2,
    "retry_delay": datetime.timedelta(minutes=5)
}

# Function to fetch datim_ids from the database
def fetch_datim_ids(**kwargs):
    hook = PostgresHook(postgres_conn_id="lamisplus_conn")
    sql = "SELECT datim_id FROM central_partner_mapping"
    records = hook.get_records(sql)
    datim_ids = [record[0] for record in records]  # Extract datim_id from the records
    return datim_ids

def create_task_groups(datim_id):
    """
    Dynamically creates task groups for each datim_id.
    """
    with TaskGroup(group_id=f"tasks_for_{datim_id}") as datim_tasks:
        
        radet_joined = PostgresOperator(
           task_id="radet_joined",
           postgres_conn_id="lamisplus_conn",
           sql= f"call expanded_radet_client.proc_radet_joined('{datim_id}')",
           autocommit=True
           )

        [radet_joined]

    return datim_tasks

# Define the DAG
with DAG("test_radet_joined_with_datim",
         start_date=datetime.datetime(2024, 7, 1),
         schedule_interval=None,
         default_args=default_args,
         catchup=True,
         max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
    # List of datim_ids
    datim_ids = fetch_datim_ids()

    # Dynamically create tasks for each datim_id
    task_group_endpoints = [create_task_groups(datim_id) for datim_id in datim_ids]

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )

    # Define task dependencies
    start >> task_group_endpoints >> end
