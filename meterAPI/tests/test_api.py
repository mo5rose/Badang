# meterapi/tests/test_api.py
import pytest
from fastapi.testclient import TestClient
from meterapi.main import app

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Welcome to meterAPI"}

def test_predictive_maintenance():
    response = client.post("/predict", json={"sensor_data": [1.0, 2.0, 3.0]})
    assert response.status_code == 200
    assert "prediction" in response.json()