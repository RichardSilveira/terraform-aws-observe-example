
# --------------------------------------------------
# Data sources
# --------------------------------------------------
data "aws_vpc" "vpc" {
  id = var.vpc_id
}

# --------------------------------------------------
# Variables to filter enabled interface endpoints
# --------------------------------------------------

locals {
  # ECR is automatically included with ECS/EKS
  ecr_needed = var.enable_ecr || var.enable_ecs || var.enable_eks

  # CloudWatch includes both monitoring and logs
  cloudwatch_enabled = var.enable_cloudwatch

  # Define all possible interface endpoints with consistent grouping
  all_endpoints = {

    # SSM Session Manager (grouped endpoints - all three required together)
    ssm = var.enable_ssm_session_manager ? {
      service_name = "com.amazonaws.${var.region}.ssm"
      description  = "SSM endpoint for Session Manager"
    } : null

    ec2messages = var.enable_ssm_session_manager ? {
      service_name = "com.amazonaws.${var.region}.ec2messages"
      description  = "EC2 Messages endpoint for Session Manager"
    } : null

    ssmmessages = var.enable_ssm_session_manager ? {
      service_name = "com.amazonaws.${var.region}.ssmmessages"
      description  = "SSM Messages endpoint for Session Manager"
    } : null

    # Messaging Services
    sqs = var.enable_sqs ? {
      service_name = "com.amazonaws.${var.region}.sqs"
      description  = "Amazon SQS endpoint"
    } : null

    sns = var.enable_sns ? {
      service_name = "com.amazonaws.${var.region}.sns"
      description  = "Amazon SNS endpoint"
    } : null

    eventbridge = var.enable_eventbridge ? {
      service_name = "com.amazonaws.${var.region}.events"
      description  = "Amazon EventBridge endpoint"
    } : null

    # Compute Services
    lambda = var.enable_lambda ? {
      service_name = "com.amazonaws.${var.region}.lambda"
      description  = "AWS Lambda endpoint"
    } : null

    # Security Services
    secrets_manager = var.enable_secrets_manager ? {
      service_name = "com.amazonaws.${var.region}.secretsmanager"
      description  = "AWS Secrets Manager endpoint"
    } : null

    iam = var.enable_iam ? {
      service_name = "com.amazonaws.iam"
      description  = "AWS IAM endpoint"
    } : null

    # Monitoring Services (grouped)
    cloudwatch_monitoring = local.cloudwatch_enabled ? {
      service_name = "com.amazonaws.${var.region}.monitoring"
      description  = "Amazon CloudWatch Monitoring endpoint"
    } : null

    cloudwatch_logs = local.cloudwatch_enabled ? {
      service_name = "com.amazonaws.${var.region}.logs"
      description  = "Amazon CloudWatch Logs endpoint"
    } : null

    # Container Registry (ECR) - standalone or auto-included
    ecr_api = local.ecr_needed ? {
      service_name = "com.amazonaws.${var.region}.ecr.api"
      description  = "Amazon ECR API endpoint"
    } : null

    ecr_dkr = local.ecr_needed ? {
      service_name = "com.amazonaws.${var.region}.ecr.dkr"
      description  = "Amazon ECR Docker endpoint"
    } : null

    # ECS (includes ECR automatically)
    ecs = var.enable_ecs ? {
      service_name = "com.amazonaws.${var.region}.ecs"
      description  = "Amazon ECS endpoint"
    } : null

    ecs_agent = var.enable_ecs ? {
      service_name = "com.amazonaws.${var.region}.ecs-agent"
      description  = "Amazon ECS Agent endpoint"
    } : null

    ecs_telemetry = var.enable_ecs ? {
      service_name = "com.amazonaws.${var.region}.ecs-telemetry"
      description  = "Amazon ECS Telemetry endpoint"
    } : null

    # EKS (includes ECR automatically)
    eks = var.enable_eks ? {
      service_name = "com.amazonaws.${var.region}.eks"
      description  = "Amazon EKS endpoint"
    } : null

    eks_auth = var.enable_eks ? {
      service_name = "com.amazonaws.${var.region}.eks-auth"
      description  = "Amazon EKS Auth endpoint"
    } : null
  }

  # Filter out null values to get only enabled endpoints
  enabled_endpoints = {
    for key, endpoint in local.all_endpoints : key => endpoint
    if endpoint != null
  }
}

# --------------------------------------------------
# Security group for interface VPC endpoints
# --------------------------------------------------
resource "aws_security_group" "interface_endpoints_sg" {
  count       = length(local.enabled_endpoints) > 0 ? 1 : 0
  name_prefix = "${var.name}-interface-endpoints-sg"
  description = "Security group for VPC interface endpoints"
  vpc_id      = var.vpc_id

  # Allow HTTPS traffic from within the VPC (required for VPC endpoints)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    description = "Allow HTTPS traffic from VPC CIDR for VPC endpoint access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-interface-endpoints-sg"
  })
}

# --------------------------------------------------
# Create one VPC endpoint per enabled service, each spanning ALL specified subnets
# --------------------------------------------------
resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = local.enabled_endpoints

  vpc_id              = var.vpc_id
  service_name        = each.value.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids # This creates network interfaces in ALL subnets
  security_group_ids  = length(local.enabled_endpoints) > 0 ? [aws_security_group.interface_endpoints_sg[0].id] : []
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name        = "${var.name}-${each.key}-endpoint"
    ServiceType = each.key
    Description = each.value.description
  })
}
