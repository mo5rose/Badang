# src/quality/framework.py
from pyspark.sql import SparkSession
from datetime import datetime
import json

class DataQualityChecker:
    def __init__(self, spark_session):
        self.spark = spark_session
        
    def check_completeness(self, df, column):
        total = df.count()
        non_null = df.filter(df[column].isNotNull()).count()
        return {
            'metric': 'completeness',
            'column': column,
            'score': non_null/total if total > 0 else 0
        }
    
    def check_uniqueness(self, df, column):
        total = df.count()
        unique = df.select(column).distinct().count()
        return {
            'metric': 'uniqueness',
            'column': column,
            'score': unique/total if total > 0 else 0
        }
    
    def run_checks(self, df, checks_config):
        results = []
        for check in checks_config:
            if check['type'] == 'completeness':
                results.append(
                    self.check_completeness(df, check['column'])
                )
            elif check['type'] == 'uniqueness':
                results.append(
                    self.check_uniqueness(df, check['column'])
                )
        
        return {
            'timestamp': datetime.now().isoformat(),
            'results': results
        }