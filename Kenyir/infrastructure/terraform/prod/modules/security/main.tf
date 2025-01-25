# modules/security/main.tf
# KMS for encryption
resource "aws_kms_key" "datalake" {
  description             = "KMS key for Data Lake encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# WAF for API protection
resource "aws_wafv2_web_acl" "datalake_api" {
  name        = "datalake-${var.environment}-waf"
  description = "WAF for Data Lake API protection"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "datalake-waf"
    sampled_requests_enabled  = true
  }
}

# Security Groups
resource "aws_security_group" "datalake_internal" {
  name        = "datalake-${var.environment}-internal"
  description = "Security group for internal Data Lake components"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Roles and Policies
resource "aws_iam_role" "datalake_service" {
  name = "datalake-${var.environment}-service"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "datalake_service" {
  name = "datalake-${var.environment}-service-policy"
  role = aws_iam_role.datalake_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          aws_kms_key.datalake.arn,
          "arn:aws:s3:::datalake-${var.environment}-*/*"
        ]
      }
    ]
  })
}

# Secret Manager
resource "aws_secretsmanager_secret" "datalake" {
  name = "datalake-${var.environment}"
  kms_key_id = aws_kms_key.datalake.arn
}

resource "aws_secretsmanager_secret_version" "datalake" {
  secret_id = aws_secretsmanager_secret.datalake.id
  secret_string = jsonencode({
    MINIO_ROOT_USER     = random_string.minio_user.result
    MINIO_ROOT_PASSWORD = random_password.minio_password.result
    DB_PASSWORD         = random_password.db_password.result
    GRAFANA_PASSWORD    = random_password.grafana_password.result
  })
}

# SSL/TLS Certificates
resource "aws_acm_certificate" "datalake" {
  domain_name       = "datalake.${var.domain_name}"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.datalake.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Network Firewall Rules
resource "aws_networkfirewall_rule_group" "datalake" {
  capacity = 100
  name     = "datalake-${var.environment}-rules"
  type     = "STATEFUL"
  
  rule_group {
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          protocol        = "TCP"
          direction       = "ANY"
          source_port     = "ANY"
          source         = "ANY"
        }
        rule_option {
          keyword = "sid:1"
        }
      }
    }
  }
}