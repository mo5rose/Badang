# infrastructure/scripts/backup_manager.py
import boto3
import schedule
import time
from datetime import datetime

class BackupManager:
    def __init__(self):
        self.s3_client = boto3.client('s3')
        self.backup_bucket = 'datalake-backup'
        self.retention_days = 30

    def backup_minio(self):
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Backup MinIO data
        for bucket in ['raw-data', 'processed-data', 'curated-data']:
            backup_key = f'minio/{bucket}/{timestamp}/'
            self.sync_bucket(bucket, self.backup_bucket, backup_key)

    def backup_metadata(self):
        # Backup PostgreSQL
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_key = f'postgres/backup_{timestamp}.sql'
        
        # Execute pg_dump and upload
        import subprocess
        dump_cmd = f"pg_dump -h localhost -U datalake -F c -f /tmp/backup.sql"
        subprocess.run(dump_cmd, shell=True)
        
        self.s3_client.upload_file(
            '/tmp/backup.sql',
            self.backup_bucket,
            backup_key
        )

    def cleanup_old_backups(self):
        import datetime
        cutoff_date = datetime.datetime.now() - datetime.timedelta(days=self.retention_days)
        
        paginator = self.s3_client.get_paginator('list_objects_v2')
        for page in paginator.paginate(Bucket=self.backup_bucket):
            for obj in page.get('Contents', []):
                if obj['LastModified'] < cutoff_date:
                    self.s3_client.delete_object(
                        Bucket=self.backup_bucket,
                        Key=obj['Key']
                    )

    def run_backup_schedule(self):
        schedule.every().day.at("01:00").do(self.backup_minio)
        schedule.every().day.at("02:00").do(self.backup_metadata)
        schedule.every().week.do(self.cleanup_old_backups)

        while True:
            schedule.run_pending()
            time.sleep(60)

if __name__ == "__main__":
    backup_manager = BackupManager()
    backup_manager.run_backup_schedule()