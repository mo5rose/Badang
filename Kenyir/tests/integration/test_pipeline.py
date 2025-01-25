# tests/integration/test_pipeline.py
import pytest
from pyspark.sql import SparkSession
import pandas as pd

def test_end_to_end_pipeline(spark, minio_client):
    # Create test data
    test_data = pd.DataFrame({
        'id': range(1, 1001),
        'value': ['test' + str(i) for i in range(1, 1001)]
    })
    
    # Write to raw bucket
    test_data.to_csv('/tmp/test.csv', index=False)
    minio_client.fput_object('raw-data', 'test.csv', '/tmp/test.csv')
    
    # Run processing job
    df = spark.read.csv('s3a://raw-data/test.csv', header=True)
    processed_df = df.withColumn('processed', df.value.concat('_processed'))
    processed_df.write.parquet('s3a://processed-data/test_output')
    
    # Verify results
    result_df = spark.read.parquet('s3a://processed-data/test_output')
    assert result_df.count() == 1000
    assert 'processed' in result_df.columns