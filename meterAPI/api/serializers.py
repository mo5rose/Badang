# meterapi/api/serializers.py
from pydantic import BaseModel

class MeterData(BaseModel):
    timestamp: str
    value: float

class PredictionResponse(BaseModel):
    prediction: float