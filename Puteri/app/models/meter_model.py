from pydantic import BaseModel
from datetime import datetime

class MeterData(BaseModel):
    Timestamp: datetime
    Value: float