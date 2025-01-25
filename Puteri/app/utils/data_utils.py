def handle_missing_data(data):
    # Forward fill missing values
    data["Value"] = data["Value"].ffill()
    return data