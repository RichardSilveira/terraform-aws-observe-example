# --------------------------------------------------
# Observe Platform Outputs
# --------------------------------------------------
output "observe_firehose_arn" {
  description = "ARN of the Observe Kinesis Firehose delivery stream"
  value       = module.observe_kinesis_firehose.firehose_delivery_stream.arn
}

output "observe_firehose_name" {
  description = "Name of the Observe Kinesis Firehose delivery stream"
  value       = module.observe_kinesis_firehose.firehose_delivery_stream.name
}

output "observe_s3_backup_bucket" {
  description = "S3 bucket used for Observe Firehose failed events backup"
  value       = aws_s3_bucket.observe_firehose_failed_events.id
}

output "observe_cloudwatch_destination_arn" {
  description = "ARN of the CloudWatch Logs destination for Observe"
  value       = aws_cloudwatch_log_destination.to_firehose.arn
}

output "observe_cloudwatch_destination_name" {
  description = "Name of the CloudWatch Logs destination for Observe"
  value       = aws_cloudwatch_log_destination.to_firehose.name
}

output "observe_s3_forwarder_lambda_name" {
  description = "Name of the Observe S3 forwarder Lambda function"
  value       = module.observe_s3_forwarder_lambda.lambda_function.function_name
}

# --------------------------------------------------
# Mock Resources Outputs
# --------------------------------------------------
output "mock_lambda_function_name" {
  description = "Name of the mock Lambda function"
  value       = module.mock_lambda.function_name
}

output "mock_lambda_function_arn" {
  description = "ARN of the mock Lambda function"
  value       = module.mock_lambda.function_arn
}

output "mock_s3_log_bucket_name" {
  description = "Name of the mock S3 log storage bucket"
  value       = aws_s3_bucket.mock_log_storage.id
}

output "mock_s3_log_bucket_arn" {
  description = "ARN of the mock S3 log storage bucket"
  value       = aws_s3_bucket.mock_log_storage.arn
}

# --------------------------------------------------
# VPC outputs
# --------------------------------------------------
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "The IDs of the NAT Gateways"
  value       = module.networking.nat_gateway_ids
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = module.networking.internet_gateway_id
}

# --------------------------------------------------
# Interface Endpoints outputs
# --------------------------------------------------
output "interface_vpc_endpoint_ids" {
  description = "List of interface VPC endpoint IDs for security group associations"
  value       = module.networking.interface_vpc_endpoint_ids
}

output "interface_endpoints_security_group_id" {
  description = "Security group ID for interface VPC endpoints"
  value       = module.networking.interface_endpoints_security_group_id
}

output "interface_endpoint_dns_names" {
  description = "Map of interface endpoint DNS names by service"
  value       = module.networking.interface_endpoint_dns_names
}

output "interface_endpoint_details" {
  description = "Detailed information about all interface endpoints"
  value       = module.networking.interface_endpoint_details
}

output "enabled_interface_endpoint_services" {
  description = "List of enabled interface endpoint services"
  value       = module.networking.enabled_interface_endpoint_services
}

# --------------------------------------------------
# Cross-Account Source Account Outputs (Optional)
# --------------------------------------------------
output "source_account_lambda_function_name" {
  description = "Name of the mock Lambda function in the source account"
  value       = var.source_account_profile != null ? aws_lambda_function.source_mock_lambda.function_name : null
}

output "source_account_lambda_log_group_name" {
  description = "Name of the CloudWatch Log Group for the source account Lambda"
  value       = var.source_account_profile != null ? aws_cloudwatch_log_group.source_mock_lambda.name : null
}

output "source_account_id" {
  description = "AWS Account ID of the source account"
  value       = var.source_account_profile != null ? data.aws_caller_identity.source_account.account_id : null
}
