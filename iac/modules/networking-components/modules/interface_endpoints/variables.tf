# --------------------------------------------------
# Service-Specific Interface Endpoint Options (Grouped by Functionality)
# --------------------------------------------------

variable "enable_ssm_session_manager" {
  description = "Enable SSM Session Manager endpoints (includes: ssm, ec2messages, ssmmessages)."
  type        = bool
  default     = false
}

variable "enable_sqs" {
  description = "Enable Amazon SQS interface endpoint."
  type        = bool
  default     = false
}

variable "enable_sns" {
  description = "Enable Amazon SNS interface endpoint."
  type        = bool
  default     = false
}

variable "enable_eventbridge" {
  description = "Enable Amazon EventBridge interface endpoint."
  type        = bool
  default     = false
}

variable "enable_lambda" {
  description = "Enable AWS Lambda interface endpoint."
  type        = bool
  default     = false
}

variable "enable_secrets_manager" {
  description = "Enable AWS Secrets Manager interface endpoint."
  type        = bool
  default     = false
}

variable "enable_iam" {
  description = "Enable AWS IAM interface endpoint."
  type        = bool
  default     = false
}

variable "enable_cloudwatch" {
  description = "Enable Amazon CloudWatch interface endpoints (monitoring, logs)."
  type        = bool
  default     = false
}

# --------------------------------------------------
# Container Services (with automatic ECR inclusion)
# --------------------------------------------------
variable "enable_ecr" {
  description = "Enable Amazon ECR interface endpoints (ecr.api, ecr.dkr) - standalone for EC2 Docker usage."
  type        = bool
  default     = false
}

variable "enable_ecs" {
  description = "Enable Amazon ECS interface endpoints (ecs, ecs-agent, ecs-telemetry) - includes ECR automatically."
  type        = bool
  default     = false
}

variable "enable_eks" {
  description = "Enable Amazon EKS interface endpoints (eks, eks-auth) - includes ECR automatically."
  type        = bool
  default     = false
}

# --------------------------------------------------
# Core Configuration
# --------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC where the endpoints will be created."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the VPC endpoints will be created."
  type        = list(string)
}

variable "region" {
  description = "AWS region for VPC endpoints service names."
  type        = string
}

variable "name" {
  description = "The name prefix for the VPC endpoints."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all interface endpoint resources."
  type        = map(string)
  default     = {}
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs that should be allowed to access the interface endpoints."
  type        = list(string)
  default     = []
}
