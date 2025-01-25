# dependency_manager.py
from dependency_injector import containers, providers
from ai.predictive_maintenance import PredictiveMaintenance
from ai.anomaly_detection import AnomalyDetection

class Container(containers.DeclarativeContainer):
    anomaly_detection = providers.Singleton(AnomalyDetection, data_path="path/to/data.csv")
    predictive_maintenance = providers.Singleton(
        PredictiveMaintenance,
        data_path="path/to/data.csv",
        anomaly_detection=anomaly_detection
    )

# Initialize dependencies
dependencies = Container()