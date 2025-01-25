# src/utils/storage_init.py
from minio import Minio
import os

def initialize_storage():
    client = Minio(
        "localhost:9000",
        access_key="minioadmin",
        secret_key="minioadmin",
        secure=False
    )
    
    buckets = ['raw-data', 'processed-data', 'curated-data']
    for bucket in buckets:
        if not client.bucket_exists(bucket):
            client.make_bucket(bucket)
            print(f"Created bucket: {bucket}")
            
        # Set bucket policy for read/write
        policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {"AWS": ["*"]},
                    "Action": ["s3:GetObject", "s3:PutObject"],
                    "Resource": [f"arn:aws:s3:::{bucket}/*"]
                }
            ]
        }
        client.set_bucket_policy(bucket, policy)

if __name__ == "__main__":
    initialize_storage()