-- src/trino/init/create_schemas.sql
CREATE SCHEMA IF NOT EXISTS raw
WITH (location = 's3a://raw-data/');

CREATE SCHEMA IF NOT EXISTS processed
WITH (location = 's3a://processed-data/');

CREATE SCHEMA IF NOT EXISTS curated
WITH (location = 's3a://curated-data/');