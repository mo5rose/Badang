# infrastructure/terraform/ecr/main.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "datalake" {
  for_each = toset([
    "spark-master",
    "spark-worker",
    "trino",
    "airflow",
    "minio"
  ])
  
  name                 = "datalake-${each.key}"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "cleanup" {
  for_each   = aws_ecr_repository.datalake
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 30 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }]
  })
}