import fastapi
import pandas as pd
from fastapi import APIRouter, HTTPException
from app.services.forecast_service import generate_forecasts
from app.models.forecast_model import ForecastRequest

router = APIRouter()

@router.post("/forecast")
def get_forecast(request: ForecastRequest):
    try:
        # Convert request to DataFrame
        data = pd.DataFrame(request.data)
        
        # Generate forecasts
        forecast_data = generate_forecasts(data, request.horizon)
        
        return forecast_data.to_dict(orient="records")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))