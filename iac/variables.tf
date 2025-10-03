variable "owner" {
  description = "The owner of the resources."
  type        = string
}

variable "cost_center" {
  description = "The cost center associated with the resources."
  type        = string
  default     = null
}

variable "project" {
  description = "The project name for the resources."
  type        = string
}

variable "environment" {
  description = "The environment for the resources (e.g., dev, staging, prod)."
  type        = string
}

variable "created_by" {
  description = "The arn of the IAM user or role that create the resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = null
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = null
}

# --------------------------------------------------
# Observe Platform Variables
# --------------------------------------------------
variable "observe_customer" {
  description = "Observe Customer ID"
  type        = string
}

variable "observe_collection_endpoint" {
  description = "Observe collection endpoint, e.g. https://123456789012.collect.observeinc.com (us-west-2) or https://123456789012.collect.us-east-1.observeinc.com per Observe docs"
  type        = string
}

variable "observe_token" {
  description = "Observe authentication token"
  type        = string
  sensitive   = true
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = null
}
