# src/spark/jobs/example_job.py
from pyspark.sql import SparkSession

def create_spark_session():
    return SparkSession.builder \
        .appName("DataLakeJob") \
        .config("spark.sql.warehouse.dir", "s3a://processed-data/warehouse") \
        .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
        .config("spark.hadoop.fs.s3a.access.key", "minioadmin") \
        .config("spark.hadoop.fs.s3a.secret.key", "minioadmin") \
        .config("spark.hadoop.fs.s3a.path.style.access", True) \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .getOrCreate()

def process_data():
    spark = create_spark_session()
    
    # Example processing
    df = spark.read.csv("s3a://raw-data/sample.csv")
    processed_df = df.transform(your_processing_logic)
    processed_df.write.parquet("s3a://processed-data/output")
    
    spark.stop()

def your_processing_logic(df):
    # Add your transformations here
    return df