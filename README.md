# Project Overview

This project is a predictive maintenance system for IFIX meter data. It consists of the following components:

- **Kenyir:** On-prem data lake for storing meter data.
- **meterAPI:** Middleware for data ingestion and AI predictions.
- **Puteri:** Analytics and dashboard for visualizing data.

## Setup
1. Clone the repository.
2. Install dependencies: `pip install -r requirements.txt`.
3. Run the API server: `uvicorn api.main:app --host 0.0.0.0 --port 8000`.