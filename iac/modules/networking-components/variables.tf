variable "vpc_config" {
  description = "VPC Configuration."
  type = object({
    name                     = string
    cidr_block               = string
    public_subnet_1_cidr     = string
    public_subnet_1_az       = string
    public_subnet_2_cidr     = string
    public_subnet_2_az       = string
    public_subnet_3_cidr     = optional(string)
    public_subnet_3_az       = optional(string)
    private_subnet_1_cidr    = string
    private_subnet_1_az      = string
    private_subnet_2_cidr    = string
    private_subnet_2_az      = string
    private_subnet_3_cidr    = optional(string)
    private_subnet_3_az      = optional(string)
    create_second_nat        = optional(bool, true)
    vpc_enable_dns_hostnames = optional(bool, true)
  })
}

# =============================================================================
# Interface Endpoints Configuration
# =============================================================================

variable "interface_endpoints_config" {
  description = "Interface VPC Endpoints Configuration."
  type = object({
    name = string

    # Service-specific endpoint options (grouped by functionality)
    enable_ssm_session_manager = optional(bool, false) # Includes: ssm, ec2messages, ssmmessages
    enable_sqs                 = optional(bool, false)
    enable_sns                 = optional(bool, false)
    enable_eventbridge         = optional(bool, false)
    enable_lambda              = optional(bool, false)
    enable_secrets_manager     = optional(bool, false)
    enable_iam                 = optional(bool, false)
    enable_cloudwatch          = optional(bool, false) # Includes: monitoring, logs

    # Container services (ECR auto-included with ECS/EKS)
    enable_ecr = optional(bool, false) # Standalone for EC2 Docker usage
    enable_ecs = optional(bool, false) # Includes: ecs, ecs-agent, ecs-telemetry + ECR
    enable_eks = optional(bool, false) # Includes: eks, eks-auth + ECR
  })
  default = {
    name                       = "no-interface-endpoints"
    enable_ssm_session_manager = false
    enable_sqs                 = false
    enable_sns                 = false
    enable_eventbridge         = false
    enable_lambda              = false
    enable_secrets_manager     = false
    enable_iam                 = false
    enable_cloudwatch          = false
    enable_ecr                 = false
    enable_ecs                 = false
    enable_eks                 = false
  }
}

variable "region" {
  description = "AWS region for VPC endpoints."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
