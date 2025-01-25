# tests/conftest.py
import pytest
from minio import Minio
from pyspark.sql import SparkSession
import docker

@pytest.fixture(scope="session")
def spark():
    return SparkSession.builder \
        .appName("TestDataLake") \
        .master("local[*]") \
        .getOrCreate()

@pytest.fixture(scope="session")
def minio_client():
    return Minio(
        "localhost:9000",
        access_key="minioadmin",
        secret_key="minioadmin",
        secure=False
    )

@pytest.fixture(scope="session")
def docker_setup():
    client = docker.from_env()
    containers = client.containers.list()
    return {c.name: c for c in containers}