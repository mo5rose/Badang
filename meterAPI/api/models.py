# meterapi/api/models.py
from sqlalchemy import Column, Integer, String, Float
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class MeterData(Base):
    __tablename__ = "meter_data"
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(String)
    value = Column(Float)