# modules/security/outputs.tf
output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.datalake.arn
}

output "security_group_id" {
  description = "ID of the main security group"
  value       = aws_security_group.datalake_internal.id
}

output "service_role_arn" {
  description = "ARN of the service role"
  value       = aws_iam_role.datalake_service.arn
}

output "certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = aws_acm_certificate.datalake.arn
}