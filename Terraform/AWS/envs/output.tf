output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.me.account_id
}

output "arn" {
  description = "The ARN of the caller identity"
  value       = data.aws_caller_identity.me.arn
}

output "region" {
  description = "The current AWS region"
  value       = data.aws_region.current.id
}