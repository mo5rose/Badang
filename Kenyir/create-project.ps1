# Create project structure (save as create-project.ps1)
$projectStructure = @'
datalake-project/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── cd.yml
├── src/
│   ├── airflow/
│   │   ├── dags/
│   │   └── plugins/
│   ├── spark/
│   │   ├── jobs/
│   │   └── config/
│   └── trino/
│       └── catalog/
├── infrastructure/
│   ├── docker/
│   │   ├── airflow/
│   │   ├── spark/
│   │   └── trino/
│   └── terraform/
│       ├── dev/
│       ├── test/
│       └── prod/
├── tests/
│   ├── unit/
│   └── integration/
└── docs/
    ├── architecture/
    └── operations/
'@

# Create directories
$projectStructure -split "`n" | ForEach-Object {
    if ($_ -match "^(.+)/$") {
        $dir = $matches[1].Trim()
        New-Item -ItemType Directory -Path $dir -Force
    }
}