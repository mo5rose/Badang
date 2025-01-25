import fastapi
from fastapi import APIRouter
from app.services.data_service import fetch_meter_data

router = APIRouter()

@router.get("/data/meter")
def get_meter_data():
    return fetch_meter_data()