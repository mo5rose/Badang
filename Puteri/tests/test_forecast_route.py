import pytest
from services.forecast_service import generate_forecasts
import pandas as pd

def test_generate_forecasts():
    # Create sample data
    data = pd.DataFrame({
        "Timestamp": pd.date_range(start="2023-01-01", periods=10, freq="D"),
        "Value": range(10)
    })
    
    # Generate forecasts
    forecast_horizon = 5
    forecast_data = generate_forecasts(data, forecast_horizon)
    
    # Check if the forecast has the correct number of rows
    assert len(forecast_data) == len(data) + forecast_horizon
    
    # Check if the forecast columns are present
    assert "Timestamp" in forecast_data.columns
    assert "Value" in forecast_data.columns
    assert "Error_Lower" in forecast_data.columns
    assert "Error_Upper" in forecast_data.columns
    assert "Type" in forecast_data.columns
    
    # Check if the forecast type is correct
    assert all(forecast_data["Type"] == "Forecast")