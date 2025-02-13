# setup.py
from setuptools import setup, find_packages

setup(
    name="enterprise_datalake",
    version="1.0.0",
    packages=find_packages(),
    install_requires=[
        "azure-storage-blob>=12.0.0",
        "azure-identity>=1.5.0",
        "azure-mgmt-resource>=21.0.0",
        "azure-mgmt-storage>=19.0.0",
        "azure-servicebus>=7.0.0",
        "azure-eventhub>=5.0.0",
        "azure-mgmt-recoveryservices>=1.0.0",
        "azure-mgmt-backup>=1.0.0",
        "azure-mgmt-costmanagement>=1.0.0",
        "pyspark>=3.5.0",
        "delta-spark>=2.0.0",
        "pandas>=2.0.0",
        "numpy>=1.20.0",
        "PyYAML>=6.0",
        "asyncio>=3.4.3",
        "prometheus_client>=0.9.0",
        "great_expectations>=0.15.0"
    ],
    python_requires=">=3.8",
)