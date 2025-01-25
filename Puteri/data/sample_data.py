import pandas as pd

def get_real_data():
    """
    Load and preprocess time series data.
    """
    data = pd.read_csv("data/meter_readings.csv")
    data["Timestamp"] = pd.to_datetime(data["Timestamp"])
    data = data.sort_values(by="Timestamp")
    data = handle_missing_data(data)
    data = data.set_index("Timestamp")
    data = data.resample("D").mean().reset_index()
    data["Error_Upper"], data["Error_Lower"] = calculate_errors(data["Value"])
    return data

def handle_missing_data(data):
    """
    Handle missing data points using forward fill.
    """
    data["Value"] = data["Value"].ffill()
    return data

def calculate_errors(values, window_size=7):
    """
    Compute asymmetric error bars using rolling statistics.
    """
    rolling_mean = values.rolling(window=window_size).mean()
    rolling_std = values.rolling(window=window_size).std()
    error_upper = rolling_mean + rolling_std
    error_lower = rolling_mean - rolling_std
    error_upper = error_upper.ffill().bfill()
    error_lower = error_lower.ffill().bfill()
    return error_upper, error_lower