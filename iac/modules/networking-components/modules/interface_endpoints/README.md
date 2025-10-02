# Interface VPC Endpoints Module

This module creates AWS VPC Interface Endpoints for private connectivity to AWS services using AWS PrivateLink. It supports multiple AWS services with explicit, service-specific configuration options.

## Features

- **Service-Specific Configuration**: Explicit boolean flags for each supported service
- **Automatic Service Grouping**: Related services are grouped together (e.g., SSM Session Manager, CloudWatch)
- **Smart Dependencies**: ECS and EKS automatically include ECR endpoints
- **Zero-Trust Security**: Security groups with no ingress rules by default
- **Multi-AZ Deployment**: Single endpoint spanning multiple subnets for high availability
- **Backward Compatibility**: Legacy SSM configuration still supported

## Supported Services

### Core AWS Services
- **SSM Session Manager**: `enable_ssm_session_manager` (includes ssm, ec2messages, ssmmessages)
- **Secrets Manager**: `enable_secrets_manager`
- **IAM**: `enable_iam`
- **CloudWatch**: `enable_cloudwatch` (includes monitoring and logs)

### Messaging & Events
- **SQS**: `enable_sqs`
- **SNS**: `enable_sns`
- **EventBridge**: `enable_eventbridge`

### Compute & Containers
- **Lambda**: `enable_lambda`
- **ECR**: `enable_ecr` (standalone for EC2 Docker usage)
- **ECS**: `enable_ecs` (automatically includes ECR)
- **EKS**: `enable_eks` (automatically includes ECR)

## Service Dependencies

The module automatically handles service dependencies:

- **ECS** → Includes ECR (api + dkr) for container image pulling
- **EKS** → Includes ECR (api + dkr) for container image pulling
- **SSM Session Manager** → Includes ssm, ec2messages, ssmmessages
- **CloudWatch** → Includes monitoring and logs endpoints

## Usage Examples

### Basic SSM Session Manager (Backward Compatible)
```hcl
module "interface_endpoints" {
  source = "./modules/interface_endpoints"

  # Legacy configuration (still supported)
  create_ssm_endpoints = true
  name                 = "my-ssm-endpoints"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  region     = var.region
}
```

### New Service-Specific Configuration
```hcl
module "interface_endpoints" {
  source = "./modules/interface_endpoints"

  name = "my-interface-endpoints"

  # Explicit service configuration
  enable_ssm_session_manager = true
  enable_secrets_manager     = true
  enable_cloudwatch          = true
  enable_sqs                 = true
  enable_sns                 = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  region     = var.region
}
```
    Project     = "my-project"
  }
}
```

## Security Model

The module follows a zero-trust security approach:

1. **Restrictive Security Group**: VPC endpoints are created with a security group that has no ingress rules
2. **Explicit Access**: Access must be granted via `aws_vpc_endpoint_security_group_association` resources
3. **Principle of Least Privilege**: Only necessary outbound traffic is allowed

## Outputs

- `ssm_vpc_endpoint_ids`: List of all endpoint IDs for security group associations
- `ssm_endpoints_security_group_id`: Security group ID for the endpoints
- `ssm_endpoint_dns_names`: DNS names for all endpoints (by service name)
- `ssm_endpoint_details`: Comprehensive endpoint information including network interface IDs
