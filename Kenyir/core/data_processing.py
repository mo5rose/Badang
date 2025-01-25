# core/data_processing.py
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from typing import Optional, Dict, Any

class DataProcessor:
    def __init__(self, config: Dict[str, Any]):
        self.spark = self._initialize_spark()
        self.config = config

    def _initialize_spark(self) -> SparkSession:
        return SparkSession.builder \
            .appName("EnterpriseDataLake") \
            .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
            .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
            .config("spark.databricks.delta.schema.autoMerge.enabled", "true") \
            .config("spark.databricks.delta.optimizeWrite.enabled", "true") \
            .config("spark.databricks.delta.autoCompact.enabled", "true") \
            .getOrCreate()

    async def process_data(self, 
                          data: Union[pd.DataFrame, pyspark.sql.DataFrame],
                          zone: DataZone,
                          processing_type: str) -> Optional[Union[pd.DataFrame, pyspark.sql.DataFrame]]:
        """Process data based on zone and type"""
        try:
            if processing_type == "cleanse":
                return await self._cleanse_data(data)
            elif processing_type == "enrich":
                return await self._enrich_data(data)
            elif processing_type == "transform":
                return await self._transform_data(data)
            else:
                raise ValueError(f"Unknown processing type: {processing_type}")
        except Exception as e:
            self.logger.error(f"Error processing data: {str(e)}")
            raise