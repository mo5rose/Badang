-- src/postgres/init/01_init_schemas.sql
CREATE SCHEMA IF NOT EXISTS metadata;
CREATE SCHEMA IF NOT EXISTS lineage;
CREATE SCHEMA IF NOT EXISTS quality;

-- Metadata tables
CREATE TABLE metadata.data_assets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    location VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    schema JSONB
);

CREATE TABLE metadata.processing_jobs (
    id SERIAL PRIMARY KEY,
    job_name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    parameters JSONB,
    logs TEXT
);

-- Data quality tables
CREATE TABLE quality.quality_checks (
    id SERIAL PRIMARY KEY,
    asset_id INTEGER REFERENCES metadata.data_assets(id),
    check_name VARCHAR(255) NOT NULL,
    check_type VARCHAR(50) NOT NULL,
    parameters JSONB,
    status VARCHAR(50),
    last_run TIMESTAMP,
    CONSTRAINT unique_asset_check UNIQUE (asset_id, check_name)
);