# api/main.py
from fastapi import FastAPI
from ai.predictive_maintenance import PredictiveMaintenance
from ai.anomaly_detection import AnomalyDetection
from dependency_manager import dependencies

app = FastAPI()

# Initialize AI modules
predictive_maintenance = PredictiveMaintenance("path/to/data.csv")
anomaly_detection = AnomalyDetection("path/to/data.csv")

@app.post("/predictive_maintenance/train")
async def train_predictive_maintenance():
    predictive_maintenance.train("target_column")
    return {"message": "Model trained successfully"}

@app.post("/predictive_maintenance/predict")
async def predict(data: dict):
    prediction = dependencies.predictive_maintenance().predict(data["values"])
    return {"prediction": prediction}

@app.post("/anomaly_detection/train")
async def train_anomaly_detection():
    anomaly_detection.train()
    return {"message": "Model trained successfully"}

@app.post("/anomaly_detection/detect")
async def detect(data: dict):
    is_anomaly = anomaly_detection.detect(data["values"])
    return {"is_anomaly": is_anomaly}

# api/main.py
import yaml

with open("config.yml", "r") as f:
    config = yaml.safe_load(f)

# Initialize AI modules based on config
ai_modules = {}
for module in config["ai_modules"]:
    if module["name"] == "predictive_maintenance":
        ai_modules["predictive_maintenance"] = PredictiveMaintenance(module["data_path"])
    elif module["name"] == "anomaly_detection":
        ai_modules["anomaly_detection"] = AnomalyDetection(module["data_path"])