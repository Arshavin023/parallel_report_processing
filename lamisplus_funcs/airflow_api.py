import requests

def trigger_dag(dag_id, api_base_url='http://localhost:8080/api/v1'):
    url = f'{api_base_url}/dags/{dag_id}/dagRuns'
    response = requests.post(url, json={})
    if response.status_code == 200:
        print(f"DAG {dag_id} triggered successfully.")
    else:
        raise Exception(f"Failed to trigger DAG {dag_id}. Response: {response.text}")