# setup-linux-components.ps1
function Install-LinuxComponents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Development", "Testing", "Production")]
        [string]$Environment
    )

    $wslCommands = @"
#!/bin/bash
# Update package list
sudo apt-get update
sudo apt-get upgrade -y

# Install Java
sudo apt-get install -y openjdk-11-jdk

# Install Python and data science tools
sudo apt-get install -y python3-pip
pip3 install pandas numpy scipy scikit-learn jupyter

# Install Hadoop ecosystem
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
tar -xzf hadoop-3.3.6.tar.gz
mv hadoop-3.3.6 /opt/hadoop

# Install Spark
wget https://dlcdn.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz
tar -xzf spark-3.5.0-bin-hadoop3.tgz
mv spark-3.5.0-bin-hadoop3 /opt/spark

# Configure environment variables
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/.bashrc
echo 'export HADOOP_HOME=/opt/hadoop' >> ~/.bashrc
echo 'export SPARK_HOME=/opt/spark' >> ~/.bashrc
echo 'export PATH=\$PATH:\$HADOOP_HOME/bin:\$SPARK_HOME/bin' >> ~/.bashrc

# Setup Hadoop configuration
cat << EOF > /opt/hadoop/etc/hadoop/core-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOF

# Setup Spark configuration
cat << EOF > /opt/spark/conf/spark-defaults.conf
spark.master                     local[*]
spark.driver.memory              4g
spark.executor.memory            4g
spark.sql.warehouse.dir          /user/hive/warehouse
spark.sql.extensions            io.delta.sql.DeltaSparkSessionExtension
EOF
"@

    # Save WSL commands to file
    $wslScriptPath = ".\setup-linux.sh"
    $wslCommands | Out-File -FilePath $wslScriptPath -Encoding ASCII

    # Execute in WSL
    wsl --distribution Ubuntu-22.04 --user root bash $wslScriptPath

    # Install additional components based on environment
    switch($Environment) {
        "Development" {
            $devTools = @"
#!/bin/bash
# Install development tools
sudo apt-get install -y git maven
pip3 install jupyter notebook
pip3 install delta-spark
"@
            $devTools | Out-File -FilePath ".\setup-dev.sh" -Encoding ASCII
            wsl --distribution Ubuntu-22.04 --user root bash ".\setup-dev.sh"
        }
        "Production" {
            $prodTools = @"
#!/bin/bash
# Install production monitoring tools
sudo apt-get install -y prometheus-node-exporter
sudo apt-get install -y grafana
"@
            $prodTools | Out-File -FilePath ".\setup-prod.sh" -Encoding ASCII
            wsl --distribution Ubuntu-22.04 --user root bash ".\setup-prod.sh"
        }
    }
}
