# tests/test_predictive_maintenance.py
import pytest
from ai.predictive_maintenance import PredictiveMaintenance
from ai.anomaly_detection import AnomalyDetection

def test_predictive_maintenance_with_anomaly_detection():
    anomaly_detection = AnomalyDetection("path/to/data.csv")
    predictive_maintenance = PredictiveMaintenance("path/to/data.csv", anomaly_detection)
    
    # Test prediction with anomalous data
    assert predictive_maintenance.predict([1, 2, 3]) == "Anomaly detected, no prediction made"