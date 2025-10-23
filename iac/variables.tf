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

variable "observe_filedrop_access_point_arn" {
  description = "Observe Filedrop S3 Access Point ARN"
  type        = string
  default     = ""
}

variable "observe_filedrop_bucket" {
  description = "Observe Filedrop S3 bucket name"
  type        = string
  default     = ""
}

variable "observe_filedrop_bucket_prefix" {
  description = "Observe Filedrop S3 bucket prefix"
  type        = string
  default     = ""
}

# --------------------------------------------------
# Cross-Account Source Variables
# --------------------------------------------------
variable "source_account_profile" {
  description = "AWS CLI profile for the source account (where logs originate)"
  type        = string
  default     = null
}

variable "source_account_region" {
  description = "AWS region for the source account"
  type        = string
  default     = null
}

variable "cross_account_org_paths" {
  description = "List of AWS Organization paths allowed to send logs to the destination (e.g., ['o-abc123/*'])"
  type        = list(string)
  default     = []
}
