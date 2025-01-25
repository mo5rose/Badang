# tests/test_meterapi.py
import pytest
from fastapi.testclient import TestClient
from meterapi.meterapi.main import app

client = TestClient(app)

def test_ingest_data():
    response = client.post("/ingest", json={"timestamp": "2023-10-01T00:00:00", "value": 100})
    assert response.status_code == 200
    assert response.json() == {"message": "Data ingested successfully"}

def test_predict():
    response = client.post("/predict", json={"values": [1, 2, 3]})
    assert response.status_code == 200
    assert "prediction" in response.json()