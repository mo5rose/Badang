# filepath: /c:/Users/mohdf/OneDrive/Desktop/GitHub/meterAPI/predictive_maintenance/models.py
from django.db import models

class MaintenanceRecord(models.Model):
    machine_id = models.CharField(max_length=100)
    timestamp = models.DateTimeField()
    vibration_x = models.FloatField()
    vibration_y = models.FloatField()
    vibration_z = models.FloatField()
    temperature_engine = models.FloatField()
    energy_consumption = models.FloatField()
    failure_prediction = models.BooleanField()
    failure_probability = models.FloatField()

    def __str__(self):
        return f"{self.machine_id} - {self.timestamp}"