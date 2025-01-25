# meterAPI User Guide

## Overview
meterAPI is the middleware that connects IFIX systems to Kenyir and provides AI predictions.

## Endpoints
- **POST /ingest:** Ingest data from IFIX.
- **POST /predict:** Get predictions for meter data.

## Example Usage
```bash
curl -X POST http://localhost:8000/ingest -H "Content-Type: application/json" -d '{"timestamp": "2023-01-01", "value": 100}'
curl -X POST http://localhost:8000/predict -H "Content-Type: application/json" -d '{"values": [1, 2, 3]}'