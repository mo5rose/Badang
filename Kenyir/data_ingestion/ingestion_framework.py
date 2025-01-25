# data_ingestion/ingestion_framework.py
from typing import Dict, Any, Union
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from pyspark.sql import SparkSession
from delta.tables import *
import json
import yaml
import xml.etree.ElementTree as ET
from sqlalchemy import create_engine
import pymongo
from elasticsearch import Elasticsearch
from confluent_kafka import Consumer, Producer
import avro.schema
from azure.storage.blob import BlobServiceClient

class DataLakeIngestion:
    def __init__(self, config: Dict[str, Any]):
        self.spark = SparkSession.builder \
            .appName("DataLakeIngestion") \
            .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
            .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
            .getOrCreate()
        
        self.config = config

    def ingest_structured_files(self, file_path: str, file_type: str) -> Union[pd.DataFrame, pa.Table]:
        """Ingest structured file formats"""
        if file_type == 'csv':
            return pd.read_csv(file_path)
        elif file_type == 'parquet':
            return pq.read_table(file_path)
        elif file_type == 'json':
            return pd.read_json(file_path)
        elif file_type == 'xml':
            tree = ET.parse(file_path)
            # Convert XML to pandas DataFrame
            return self._xml_to_dataframe(tree)
        elif file_type == 'excel':
            return pd.read_excel(file_path)
        
    def ingest_database(self, connection_params: Dict[str, str]) -> pd.DataFrame:
        """Ingest from various databases"""
        db_type = connection_params['type']
        
        if db_type in ['postgresql', 'mysql', 'mssql', 'oracle']:
            engine = create_engine(self._build_connection_string(connection_params))
            return pd.read_sql(connection_params['query'], engine)
        
        elif db_type == 'mongodb':
            client = pymongo.MongoClient(connection_params['connection_string'])
            db = client[connection_params['database']]
            collection = db[connection_params['collection']]
            return pd.DataFrame(list(collection.find()))
            
        elif db_type == 'elasticsearch':
            es = Elasticsearch([connection_params['host']])
            response = es.search(index=connection_params['index'])
            return pd.DataFrame([hit['_source'] for hit in response['hits']['hits']])

    def ingest_streaming_data(self, streaming_config: Dict[str, str]):
        """Ingest streaming data"""
        if streaming_config['type'] == 'kafka':
            consumer = Consumer({
                'bootstrap.servers': streaming_config['bootstrap_servers'],
                'group.id': streaming_config['group_id']
            })
            consumer.subscribe([streaming_config['topic']])
            return self.spark.readStream \
                .format("kafka") \
                .option("kafka.bootstrap.servers", streaming_config['bootstrap_servers']) \
                .option("subscribe", streaming_config['topic']) \
                .load()

    def save_to_datalake(self, data: Union[pd.DataFrame, pa.Table], zone: str, table_name: str):
        """Save data to appropriate data lake zone"""
        if isinstance(data, pd.DataFrame):
            spark_df = self.spark.createDataFrame(data)
        elif isinstance(data, pa.Table):
            spark_df = self.spark.createDataFrame(data.to_pandas())
        
        # Save using Delta Lake format
        spark_df.write \
            .format("delta") \
            .mode("append") \
            .save(f"/data/{zone}/{table_name}")