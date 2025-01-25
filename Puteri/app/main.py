import fastapi
from fastapi import FastAPI
from app.routes import data_routes, forecast_routes

app = FastAPI(title="Puteri Analytics Dashboard")

# Include routes
app.include_router(data_routes.router)
app.include_router(forecast_routes.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to Puteri Analytics Dashboard"}