# core/orchestration.py
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

class DataLakeOrchestrator:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self._initialize_orchestration()

    def _initialize_orchestration(self):
        """Initialize orchestration components"""
        self.default_args = {
            'owner': 'data_lake',
            'depends_on_past': False,
            'start_date': datetime(2024, 1, 1),
            'email_on_failure': True,
            'email_on_retry': False,
            'retries': 3,
            'retry_delay': timedelta(minutes=5)
        }

    def create_pipeline(self, 
                       name: str, 
                       schedule: str, 
                       tasks: List[Dict[str, Any]]) -> DAG:
        """Create a data pipeline"""
        with DAG(
            name,
            default_args=self.default_args,
            schedule_interval=schedule,
            catchup=False
        ) as dag:
            previous_task = None
            for task in tasks:
                current_task = PythonOperator(
                    task_id=task['name'],
                    python_callable=task['callable'],
                    op_kwargs=task.get('kwargs', {})
                )
                if previous_task:
                    previous_task >> current_task
                previous_task = current_task
            return dag