import pandas as pd
import numpy as np
import requests
from prophet import Prophet

def get_real_data():
    # Load real data from a CSV file
    data = pd.read_csv("data/meter_readings.csv")
    
    # Convert Timestamp column to datetime
    data["Timestamp"] = pd.to_datetime(data["Timestamp"])
    
    return data

def get_real_data():
    # Fetch data from an API
    response = requests.get("https://api.example.com/meter-readings")
    data = pd.DataFrame(response.json())
    
    # Convert Timestamp column to datetime
    data["Timestamp"] = pd.to_datetime(data["Timestamp"])
    
    return data

def get_real_data():
    # Load real data from a CSV file
    data = pd.read_csv("data/meter_readings.csv")
    
    # Convert Timestamp column to datetime
    data["Timestamp"] = pd.to_datetime(data["Timestamp"])
    
    # Add asymmetric error columns (if not already present)
    data["Error_Upper"] = data["Value"] * 0.1  # 10% upper error
    data["Error_Lower"] = data["Value"] * 0.05  # 5% lower error
    
    return data

def get_real_data():
    # Load real data from a CSV file
    data = pd.read_csv("data/meter_readings.csv")
    
    # Convert Timestamp column to datetime
    data["Timestamp"] = pd.to_datetime(data["Timestamp"])
    
    # Example: Add error columns using different methods
    data["Error_Upper"], data["Error_Lower"] = calculate_errors(data["Value"])
    
    return data

def calculate_errors(values):
    """
    Compute asymmetric error bars using different methods.
    """
    # Method 1: Standard Deviation
    std_dev = values.std()
    error_upper_std = +std_dev
    error_lower_std = -std_dev
    
    # Method 2: Standard Error
    std_error = values.sem()
    error_upper_se = +std_error
    error_lower_se = -std_error
    
    # Method 3: Confidence Interval (95%)
    confidence_level = 0.95
    mean = values.mean()
    margin_error = 1.96 * values.sem()  # Z-score for 95% CI
    error_upper_ci = (mean + margin_error) - mean
    error_lower_ci = mean - (mean - margin_error)
    
    # Method 4: Percentage Error
    upper_percentage = 0.1  # 10% upper error
    lower_percentage = 0.05  # 5% lower error
    error_upper_pct = values * upper_percentage
    error_lower_pct = values * lower_percentage
    
    # Choose the method you want to use
    error_upper = error_upper_ci  # Using 95% CI for this example
    error_lower = error_lower_ci  # Using 95% CI for this example
    
    return error_upper, error_lower

def get_real_data():
    # Load real data from a CSV file
    data = pd.read_csv("data/meter_readings.csv")
    
    # Convert Timestamp column to datetime
    data["Timestamp"] = pd.to_datetime(data["Timestamp"])
    
    # Sort by Timestamp
    data = data.sort_values(by="Timestamp")
    
    # Handle missing data (e.g., forward fill)
    data["Value"] = data["Value"].ffill()
    
    # Resample data to a specific frequency (e.g., daily)
    data = data.set_index("Timestamp")
    data = data.resample("D").mean().reset_index()  # Daily average
    
    # Add error columns using a rolling standard deviation
    data["Error_Upper"], data["Error_Lower"] = calculate_errors(data["Value"])
    
    return data

def calculate_errors(values):
    """
    Compute asymmetric error bars for time series data.
    """
    # Use a rolling window to calculate errors
    window_size = 7  # 7-day rolling window
    rolling_mean = values.rolling(window=window_size).mean()
    rolling_std = values.rolling(window=window_size).std()
    
    # Asymmetric error bars based on rolling standard deviation
    error_upper = rolling_mean + rolling_std
    error_lower = rolling_mean - rolling_std
    
    # Fill NaN values (e.g., for the first `window_size` rows)
    error_upper = error_upper.ffill().bfill()
    error_lower = error_lower.ffill().bfill()
    
    return error_upper, error_lower

def get_real_data():
    # Load real data from a CSV file
    data = pd.read_csv("data/meter_readings.csv")
    
    # Convert Timestamp column to datetime
    data["Timestamp"] = pd.to_datetime(data["Timestamp"])
    
    # Sort by Timestamp
    data = data.sort_values(by="Timestamp")
    
    # Handle missing data (e.g., forward fill)
    data["Value"] = data["Value"].ffill()
    
    # Resample data to a specific frequency (e.g., daily)
    data = data.set_index("Timestamp")
    data = data.resample("D").mean().reset_index()  # Daily average
    
    # Add error columns using a rolling standard deviation
    data["Error_Upper"], data["Error_Lower"] = calculate_errors(data["Value"])
    
    # Generate forecasts
    forecast_data = generate_forecasts(data)
    
    # Combine historical and forecasted data
    data["Type"] = "Historical"
    forecast_data["Type"] = "Forecast"
    combined_data = pd.concat([data, forecast_data], ignore_index=True)
    
    return combined_data

def calculate_errors(values):
    """
    Compute asymmetric error bars for time series data.
    """
    # Use a rolling window to calculate errors
    window_size = 7  # 7-day rolling window
    rolling_mean = values.rolling(window=window_size).mean()
    rolling_std = values.rolling(window=window_size).std()
    
    # Asymmetric error bars based on rolling standard deviation
    error_upper = rolling_mean + rolling_std
    error_lower = rolling_mean - rolling_std
    
    # Fill NaN values (e.g., for the first `window_size` rows)
    error_upper = error_upper.ffill().bfill()
    error_lower = error_lower.ffill().bfill()
    
    return error_upper, error_lower

def generate_forecasts(data):
    """
    Generate forecasts using Facebook Prophet.
    """
    # Prepare data for Prophet
    prophet_data = data[["Timestamp", "Value"]]
    prophet_data.columns = ["ds", "y"]
    
    # Train Prophet model
    model = Prophet()
    model.fit(prophet_data)
    
    # Generate future predictions
    future = model.make_future_dataframe(periods=30)  # Forecast 30 days into the future
    forecast = model.predict(future)
    
    # Extract relevant columns
    forecast_data = forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]]
    forecast_data.columns = ["Timestamp", "Value", "Error_Lower", "Error_Upper"]
    
    return forecast_data

def get_real_data():
    # Load real data from a CSV file
    data = pd.read_csv("data/meter_readings.csv")
    
    # Convert Timestamp column to datetime
    data["Timestamp"] = pd.to_datetime(data["Timestamp"])
    
    # Sort by Timestamp
    data = data.sort_values(by="Timestamp")
    
    # Handle missing data
    data = handle_missing_data(data)
    
    # Resample data to a specific frequency (e.g., daily)
    data = data.set_index("Timestamp")
    data = data.resample("D").mean().reset_index()  # Daily average
    
    # Add error columns using a rolling standard deviation
    data["Error_Upper"], data["Error_Lower"] = calculate_errors(data["Value"])
    
    return data

def handle_missing_data(data):
    """
    Handle missing data points in the time series.
    """
    # Forward fill missing values
    data["Value"] = data["Value"].ffill()
    
    # Alternatively, use interpolation
    # data["Value"] = data["Value"].interpolate(method="linear")
    
    return data

def calculate_errors(values):
    """
    Compute asymmetric error bars for time series data.
    """
    # Use a rolling window to calculate errors
    window_size = 7  # 7-day rolling window
    rolling_mean = values.rolling(window=window_size).mean()
    rolling_std = values.rolling(window=window_size).std()
    
    # Asymmetric error bars based on rolling standard deviation
    error_upper = rolling_mean + rolling_std
    error_lower = rolling_mean - rolling_std
    
    # Fill NaN values (e.g., for the first `window_size` rows)
    error_upper = error_upper.ffill().bfill()
    error_lower = error_lower.ffill().bfill()
    
    return error_upper, error_lower

def generate_forecasts(data, horizon):
    """
    Generate forecasts using Facebook Prophet.
    """
    # Handle missing data
    data = handle_missing_data(data)
    
    # Prepare data for Prophet
    prophet_data = data[["Timestamp", "Value"]]
    prophet_data.columns = ["ds", "y"]
    
    # Train Prophet model
    model = Prophet()
    model.fit(prophet_data)
    
    # Generate future predictions
    future = model.make_future_dataframe(periods=horizon)  # Forecast for the selected horizon
    forecast = model.predict(future)
    
    # Extract relevant columns
    forecast_data = forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]]
    forecast_data.columns = ["Timestamp", "Value", "Error_Lower", "Error_Upper"]
    forecast_data["Type"] = "Forecast"
    
    return forecast_data