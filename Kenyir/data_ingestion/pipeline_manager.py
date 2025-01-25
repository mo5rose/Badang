# data_ingestion/pipeline_manager.py
from typing import Dict, List
import yaml
import logging
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor
from .ingestion_framework import DataLakeIngestion

class DataPipelineManager:
    def __init__(self, config_path: str):
        with open(config_path, 'r') as f:
            self.config = yaml.safe_load(f)
        
        self.ingestion = DataLakeIngestion(self.config)
        self.logger = logging.getLogger(__name__)

    def run_database_ingestion(self):
        """Run all configured database ingestions"""
        for db_type, db_config in self.config['databases'].items():
            try:
                data = self.ingestion.ingest_database({
                    'type': db_type,
                    **db_config
                })
                
                # Save to raw zone
                self.ingestion.save_to_datalake(
                    data,
                    'raw',
                    f"{db_type}_{datetime.now().strftime('%Y%m%d')}"
                )
                
                self.logger.info(f"Successfully ingested {db_type} data")
                
            except Exception as e:
                self.logger.error(f"Error ingesting {db_type}: {str(e)}")

    def run_file_ingestion(self):
        """Run all configured file ingestions"""
        for file_config in self.config['file_locations']['structured']:
            try:
                data = self.ingestion.ingest_structured_files(
                    file_config['path'],
                    file_config['type']
                )
                
                self.ingestion.save_to_datalake(
                    data,
                    'raw',
                    f"files_{file_config['type']}_{datetime.now().strftime('%Y%m%d')}"
                )
                
                self.logger.info(f"Successfully ingested {file_config['type']} files")
                
            except Exception as e:
                self.logger.error(f"Error ingesting {file_config['type']} files: {str(e)}")

    def run_streaming_ingestion(self):
        """Run all configured streaming ingestions"""
        for stream_type, stream_config in self.config['streaming'].items():
            try:
                stream = self.ingestion.ingest_streaming_data({
                    'type': stream_type,
                    **stream_config
                })
                
                # Process streaming data
                query = stream.writeStream \
                    .format("delta") \
                    .outputMode("append") \
                    .option("checkpointLocation", f"/data/checkpoints/{stream_type}") \
                    .start(f"/data/raw/streaming_{stream_type}")
                
                self.logger.info(f"Successfully started {stream_type} streaming")
                
            except Exception as e:
                self.logger.error(f"Error in {stream_type} streaming: {str(e)}")