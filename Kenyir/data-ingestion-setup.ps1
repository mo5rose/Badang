# data-ingestion-setup.ps1
function Initialize-DataIngestionServices {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Environment
    )

    # Install data connectors and processing tools in WSL
    $setupCommands = @"
#!/bin/bash

# Install data processing libraries
pip3 install \
    pandas \
    pyarrow \
    fastparquet \
    python-snappy \
    sqlalchemy \
    pymongo \
    pymssql \
    psycopg2-binary \
    mysql-connector-python \
    elasticsearch \
    confluent-kafka \
    avro-python3 \
    azure-storage-blob \
    delta-spark \
    great-expectations

# Install file format utilities
sudo apt-get install -y \
    unzip \
    jq \
    xml2 \
    csvkit \
    sqlite3
"@

    $setupCommands | Out-File -FilePath ".\setup-ingestion.sh" -Encoding ASCII
    wsl --distribution Ubuntu-22.04 --user root bash ".\setup-ingestion.sh"
}