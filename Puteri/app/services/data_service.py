from app.models.meter_model import MeterData
from app.utils.data_utils import handle_missing_data

def fetch_meter_data():
    # Fetch and process data
    data = MeterData.query.all()
    data = handle_missing_data(data)
    return data