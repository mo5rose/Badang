# filepath: /c:/Users/mohdf/OneDrive/Desktop/GitHub/meterAPI/predictive_maintenance/views.py
from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .serializers import MaintenanceRecordSerializer
from .models import MaintenanceRecord
from rest_framework.permissions import IsAuthenticated
from confluent_kafka import Producer
import json
import threading
from opcua import Client
import time

producer = Producer({'bootstrap.servers': 'localhost:9092'})

OPCUA_ENDPOINT = "opc.tcp://localhost:4840"  # Adjust as needed for local or production

OPCUA_CLIENT = Client(OPCUA_ENDPOINT)

def opcua_data_fetcher():
    try:
        OPCUA_CLIENT.connect()
        while True:
            # Replace with actual OPC UA node IDs
            node_value = OPCUA_CLIENT.get_node("ns=2;i=2").get_value()
            message = json.dumps({'node_value': node_value})
            producer.produce('your_topic', message)
            producer.flush()
            time.sleep(1)
    except Exception as e:
        print(f"Error: {e}")
    finally:
        OPCUA_CLIENT.disconnect()

class PredictiveMaintenanceDataView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, format=None):
        queryset = MaintenanceRecord.objects.all().order_by('-timestamp')[:1000]
        serializer = MaintenanceRecordSerializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

if __name__ == "__main__":
    threading.Thread(target=opcua_data_fetcher).start()