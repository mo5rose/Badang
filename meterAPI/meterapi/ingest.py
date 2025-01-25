# meterapi/meterapi/ingest.py
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from pydantic import BaseModel, ValidationError

def fetch_data_from_ifix():
    session = requests.Session()
    retries = Retry(total=3, backoff_factor=1, status_forcelist=[500, 502, 503, 504])
    session.mount("http://", HTTPAdapter(max_retries=retries))
    
    try:
        response = session.get("http://ifix-endpoint/data")
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching data from IFIX: {e}")
        return None
    
class MeterData(BaseModel):
    timestamp: str
    value: float

def ingest_data():
    raw_data = fetch_data_from_ifix()
    try:
        data = MeterData(**raw_data)
        # Store data in Kenyir
        with open("/path/to/kenyir/data.json", "w") as f:
            json.dump(data.dict(), f)
    except ValidationError as e:
        logger.error(f"Invalid data: {e}")