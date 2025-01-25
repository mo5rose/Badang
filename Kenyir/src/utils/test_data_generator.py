# src/utils/test_data_generator.py
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

class TestDataGenerator:
    def generate_transaction_data(self, num_records=1000):
        np.random.seed(42)
        
        dates = [
            datetime.now() - timedelta(days=x) 
            for x in range(num_records)
        ]
        
        data = {
            'transaction_id': range(1, num_records + 1),
            'date': dates,
            'amount': np.random.normal(100, 25, num_records),
            'customer_id': np.random.randint(1, 100, num_records),
            'product_id': np.random.randint(1, 50, num_records)
        }
        
        df = pd.DataFrame(data)
        return df
    
    def generate_customer_data(self, num_customers=100):
        data = {
            'customer_id': range(1, num_customers + 1),
            'name': [f'Customer_{i}' for i in range(1, num_customers + 1)],
            'email': [f'customer_{i}@example.com' for i in range(1, num_customers + 1)],
            'country': np.random.choice(['US', 'UK', 'FR', 'DE'], num_customers)
        }
        
        df = pd.DataFrame(data)
        return df

    def load_to_minio(self, minio_client):
        transactions = self.generate_transaction_data()
        customers = self.generate_customer_data()
        
        # Save to temporary files
        transactions.to_parquet('/tmp/transactions.parquet')
        customers.to_parquet('/tmp/customers.parquet')
        
        # Upload to MinIO
        minio_client.fput_object('raw-data', 'transactions.parquet', 
                                '/tmp/transactions.parquet')
        minio_client.fput_object('raw-data', 'customers.parquet', 
                                '/tmp/customers.parquet')