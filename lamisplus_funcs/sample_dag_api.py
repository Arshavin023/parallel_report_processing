# dag1.py
from airflow import DAG
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from airflow.utils.dates import days_ago
from lamisplus_funcs.airflow_api import trigger_dag

def trigger_dag_function(**kwargs):
    trigger_dag(dag_id='upsert_streaming_for_refresh_tables')  # Replace 'dag2' with the actual DAG ID of the second DAG
    
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
}

dag1 = DAG(
    'dag1',
    default_args=default_args,
    description='First DAG',
    schedule_interval=None,
    start_date=days_ago(1),
    catchup=False,
)

start = DummyOperator(
    task_id='start',
    dag=dag1,
)

end = DummyOperator(
    task_id='end',
    dag=dag1,
)

trigger_refresh_streaming_dag = PythonOperator(
    task_id='trigger_refresh_streaming_dag',
    python_callable=trigger_dag_function,
    provide_context=True,  # Allows access to context variables if needed
    dag=dag1,
)

start >> end >> trigger_refresh_streaming_dag