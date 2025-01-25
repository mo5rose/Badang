# System Architecture

## Overview
The system consists of three main components:

1. **Kenyir:** Data lake for storing meter data.
2. **meterAPI:** Middleware for data ingestion and AI predictions.
3. **Puteri:** Analytics and dashboard for visualizing data.

## Diagram
[Insert system architecture diagram here]

## Components
- **Kenyir:** PostgreSQL, MinIO, Prometheus, Grafana, ELK Stack.
- **meterAPI:** FastAPI, AI modules, CI/CD pipelines.
- **Puteri:** Dash, Plotly.