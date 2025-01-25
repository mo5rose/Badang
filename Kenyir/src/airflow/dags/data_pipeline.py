# src/airflow/dags/data_pipeline.py
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'datalake',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5)
}

dag = DAG(
    'data_pipeline',
    default_args=default_args,
    description='Data Lake Processing Pipeline',
    schedule_interval=timedelta(days=1),
    catchup=False
)

def validate_data(**context):
    # Add data validation logic
    pass

ingest_data = SparkSubmitOperator(
    task_id='ingest_data',
    application='/opt/spark/jobs/ingest_job.py',
    conn_id='spark_default',
    dag=dag
)

validate_data = PythonOperator(
    task_id='validate_data',
    python_callable=validate_data,
    dag=dag
)

process_data = SparkSubmitOperator(
    task_id='process_data',
    application='/opt/spark/jobs/process_job.py',
    conn_id='spark_default',
    dag=dag
)

ingest_data >> validate_data >> process_data