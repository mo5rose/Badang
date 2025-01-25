# filepath: /c:/Users/mohdf/OneDrive/Desktop/GitHub/meterAPI/predictive_maintenance/serializers.py
from rest_framework import serializers
from .models import MaintenanceRecord

class MaintenanceRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = MaintenanceRecord
        fields = '__all__'