# locustfile.py
from locust import HttpUser, task, between

class MeterAPIUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def get_root(self):
        self.client.get("/")

    @task
    def post_predict(self):
        self.client.post("/predict", json={"sensor_data": [1.0, 2.0, 3.0]})