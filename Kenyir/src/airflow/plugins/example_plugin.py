# Kenyir/src/airflow/plugins/example_plugin.py
from airflow.plugins_manager import AirflowPlugin

class ExamplePlugin(AirflowPlugin):
    name = "example_plugin"