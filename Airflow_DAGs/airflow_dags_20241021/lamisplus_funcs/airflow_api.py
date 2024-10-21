import requests
from requests.auth import HTTPBasicAuth

def trigger_dag(dag_id, api_base_url='http://localhost:8351/api/v1', username='Admin', password='D3ng1ne3r'):
    url = f'{api_base_url}/dags/{dag_id}/dagRuns'
    response = requests.post(url, json={}, auth=HTTPBasicAuth(username, password))
    if response.status_code == 200:
        print(f"DAG {dag_id} triggered successfully.")
    else:
        raise Exception(f"Failed to trigger DAG {dag_id}. Response: {response.text}")
