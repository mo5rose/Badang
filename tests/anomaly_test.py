# tests/anomaly_test.py
import pytest
from ai.anomaly_detection import AnomalyDetection

def test_anomaly_detection():
    anomaly_detection = AnomalyDetection("badang/kenyir/data/data.csv")
    anomaly_detection.train()
    assert anomaly_detection.detect([1, 2, 3]) == False  # Example test case