# filepath: /c:/Users/mohdf/OneDrive/Desktop/GitHub/meterAPI/Dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . /app
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=meterapi.settings
EXPOSE 8000
CMD ["sh", "-c", "python manage.py migrate && python manage.py runserver 0.0.0.0:8000"]

# meterapi/Dockerfile (New Relic APM)
FROM python:3.9-slim
RUN pip install newrelic
ENV NEW_RELIC_LICENSE_KEY=<your-license-key>
ENV NEW_RELIC_APP_NAME=meterAPI
CMD ["newrelic-admin", "run-program", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]