# Install Python dependencies
python -m pip install --upgrade pip
pip install \
    apache-airflow \
    pandas \
    pyspark \
    pytest \
    black \
    flake8 \
    pylint \
    jupyter

# Install Node.js dependencies
npm install -g \
    typescript \
    eslint \
    prettier

# Configure Git
git config --global core.autocrlf input
git config --global init.defaultBranch main

# Create Python virtual environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
