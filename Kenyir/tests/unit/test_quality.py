# tests/unit/test_quality.py
import pytest
from src.quality.framework import DataQualityChecker

def test_completeness_check(spark):
    # Create test data
    test_data = [
        (1, "test1"),
        (2, None),
        (3, "test3")
    ]
    df = spark.createDataFrame(test_data, ["id", "name"])
    
    checker = DataQualityChecker(spark)
    result = checker.check_completeness(df, "name")
    
    assert result['score'] == 2/3
    assert result['metric'] == 'completeness'

def test_uniqueness_check(spark):
    test_data = [
        (1, "test1"),
        (2, "test1"),
        (3, "test3")
    ]
    df = spark.createDataFrame(test_data, ["id", "name"])
    
    checker = DataQualityChecker(spark)
    result = checker.check_uniqueness(df, "name")
    
    assert result['score'] == 2/3