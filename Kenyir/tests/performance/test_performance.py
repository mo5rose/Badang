# tests/performance/test_performance.py
import pytest
import time
from concurrent.futures import ThreadPoolExecutor
import requests

def test_storage_performance(minio_client):
    start_time = time.time()
    
    # Upload test
    for i in range(100):
        data = b'x' * 1024 * 1024  # 1MB
        minio_client.put_object('raw-data', f'test_{i}.dat', 
                              data, len(data))
    
    upload_time = time.time() - start_time
    assert upload_time < 30  # Should complete in 30 seconds

def test_query_performance(spark):
    # Generate large dataset
    large_df = spark.range(0, 1000000)
    large_df.createOrReplaceTempView("large_table")
    
    start_time = time.time()
    result = spark.sql("""
        SELECT count(*) as count, 
               id % 100 as group_id 
        FROM large_table 
        GROUP BY id % 100
    """)
    query_time = time.time() - start_time
    
    assert query_time < 10  # Should complete in 10 seconds

def test_concurrent_access():
    def make_request():
        response = requests.get('http://localhost:9000/minio/health/live')
        return response.status_code
    
    with ThreadPoolExecutor(max_workers=50) as executor:
        results = list(executor.map(make_request, range(100)))
    
    assert all(code == 200 for code in results)