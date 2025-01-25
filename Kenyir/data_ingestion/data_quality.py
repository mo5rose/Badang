# data_ingestion/data_quality.py
from great_expectations.dataset import SparkDFDataset
from pyspark.sql.functions import col, count

class DataQualityChecker:
    def __init__(self, spark_session):
        self.spark = spark_session

    def check_data_quality(self, dataframe, table_name: str):
        """Perform data quality checks"""
        ge_df = SparkDFDataset(dataframe)
        
        # Basic quality checks
        results = {
            "null_check": ge_df.expect_column_values_to_not_be_null("*"),
            "unique_key_check": ge_df.expect_column_values_to_be_unique("id"),
            "value_ranges": ge_df.expect_column_values_to_be_between("amount", 0, 1000000),
            "data_freshness": ge_df.expect_column_values_to_be_between(
                "timestamp",
                datetime.now() - timedelta(days=1),
                datetime.now()
            )
        }
        
        return results