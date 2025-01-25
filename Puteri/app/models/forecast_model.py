from typing import List
from pydantic import BaseModel
from app.models.meter_model import MeterData

class ForecastRequest(BaseModel):
    data: List[MeterData]  # Historical data
    horizon: int  # Forecasting horizon (days)