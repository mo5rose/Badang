# core/storage_management.py
from azure.storage.blob import BlobServiceClient
from delta import *

class StorageManager:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.zones = {zone: self._create_zone(zone) for zone in DataZone}

    def _create_zone(self, zone: DataZone):
        """Create and configure storage zone"""
        return {
            'blob_container': f'{zone.value}-container',
            'delta_table': f'{zone.value}-delta',
            'retention_policy': self._get_retention_policy(zone),
            'access_tier': self._get_access_tier(zone)
        }

    def _get_retention_policy(self, zone: DataZone) -> Dict[str, Any]:
        return {
            DataZone.LANDING: {'days': 7},
            DataZone.RAW: {'days': 90},
            DataZone.CLEANSED: {'days': 180},
            DataZone.ENRICHED: {'days': 365},
            DataZone.CURATED: {'days': 730},
            DataZone.SANDBOX: {'days': 30}
        }[zone]

    def _get_access_tier(self, zone: DataZone) -> str:
        return {
            DataZone.LANDING: 'Hot',
            DataZone.RAW: 'Cool',
            DataZone.CLEANSED: 'Cool',
            DataZone.ENRICHED: 'Hot',
            DataZone.CURATED: 'Hot',
            DataZone.SANDBOX: 'Hot'
        }[zone]