# tests/test_end_to_end.py
import pytest
import requests

def test_end_to_end():
    # Step 1: Ingest data
    ingest_response = requests.post("http://localhost:8000/ingest", json={"timestamp": "2023-10-01T00:00:00", "value": 100})
    assert ingest_response.status_code == 200

    # Step 2: Make prediction
    predict_response = requests.post("http://localhost:8000/predict", json={"values": [1, 2, 3]})
    assert predict_response.status_code == 200

    # Step 3: Verify dashboard
    dashboard_response = requests.get("http://localhost:8050")
    assert dashboard_response.status_code == 200