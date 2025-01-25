# meterapi/main.py
from fastapi import Depends, FastAPI, HTTPException
from fastapi.security import OAuth2PasswordBearer
import requests
import json
import joblib

app = FastAPI()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

@app.get("/secure")
async def secure_endpoint(token: str = Depends(oauth2_scheme)):
    # Validate token (e.g., decode JWT)
    if not token:
        raise HTTPException(status_code=401, detail="Unauthorized")
    return {"message": "Secure endpoint"}

@app.post("/ingest")
async def ingest_data():
    # Fetch data from IFIX
    ifix_data = requests.get("http://ifix-endpoint/data").json()
    
    # Store data in Kenyir
    with open("/path/to/kenyir/data.json", "w") as f:
        json.dump(ifix_data, f)
    
    return {"message": "Data ingested successfully"}

# Load model
model = joblib.load("predictive_maintenance_model.pkl")

@app.post("/predict")
async def predict(data: dict):
    prediction = model.predict([data["values"]])
    return {"prediction": prediction.tolist()}