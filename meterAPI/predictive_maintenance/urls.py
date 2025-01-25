# filepath: /c:/Users/mohdf/OneDrive/Desktop/GitHub/meterAPI/predictive_maintenance/urls.py
from django.urls import path
from .views import PredictiveMaintenanceDataView

urlpatterns = [
    path('data/', PredictiveMaintenanceDataView.as_view(), name='predictive_maintenance_data'),
]