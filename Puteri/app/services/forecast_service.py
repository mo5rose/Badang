from prophet import Prophet

def generate_forecasts(data, horizon):
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
    future = model.make_future_dataframe(periods=horizon)
    forecast = model.predict(future)
    
    # Extract relevant columns
    forecast_data = forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]]
    forecast_data.columns = ["Timestamp", "Value", "Error_Lower", "Error_Upper"]
    forecast_data["Type"] = "Forecast"
    
    return forecast_data