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

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_security_group.interface_endpoints_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_endpoint.interface_endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_security_group_ids"></a> [allowed\_security\_group\_ids](#input\_allowed\_security\_group\_ids) | List of security group IDs that should be allowed to access the interface endpoints. | `list(string)` | `[]` | no |
| <a name="input_enable_cloudwatch"></a> [enable\_cloudwatch](#input\_enable\_cloudwatch) | Enable Amazon CloudWatch interface endpoints (monitoring, logs). | `bool` | `false` | no |
| <a name="input_enable_ecr"></a> [enable\_ecr](#input\_enable\_ecr) | Enable Amazon ECR interface endpoints (ecr.api, ecr.dkr) - standalone for EC2 Docker usage. | `bool` | `false` | no |
| <a name="input_enable_ecs"></a> [enable\_ecs](#input\_enable\_ecs) | Enable Amazon ECS interface endpoints (ecs, ecs-agent, ecs-telemetry) - includes ECR automatically. | `bool` | `false` | no |
| <a name="input_enable_eks"></a> [enable\_eks](#input\_enable\_eks) | Enable Amazon EKS interface endpoints (eks, eks-auth) - includes ECR automatically. | `bool` | `false` | no |
| <a name="input_enable_eventbridge"></a> [enable\_eventbridge](#input\_enable\_eventbridge) | Enable Amazon EventBridge interface endpoint. | `bool` | `false` | no |
| <a name="input_enable_iam"></a> [enable\_iam](#input\_enable\_iam) | Enable AWS IAM interface endpoint. | `bool` | `false` | no |
| <a name="input_enable_lambda"></a> [enable\_lambda](#input\_enable\_lambda) | Enable AWS Lambda interface endpoint. | `bool` | `false` | no |
| <a name="input_enable_secrets_manager"></a> [enable\_secrets\_manager](#input\_enable\_secrets\_manager) | Enable AWS Secrets Manager interface endpoint. | `bool` | `false` | no |
| <a name="input_enable_sns"></a> [enable\_sns](#input\_enable\_sns) | Enable Amazon SNS interface endpoint. | `bool` | `false` | no |
| <a name="input_enable_sqs"></a> [enable\_sqs](#input\_enable\_sqs) | Enable Amazon SQS interface endpoint. | `bool` | `false` | no |
| <a name="input_enable_ssm_session_manager"></a> [enable\_ssm\_session\_manager](#input\_enable\_ssm\_session\_manager) | Enable SSM Session Manager endpoints (includes: ssm, ec2messages, ssmmessages). | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | The name prefix for the VPC endpoints. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for VPC endpoints service names. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs where the VPC endpoints will be created. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all interface endpoint resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where the endpoints will be created. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_enabled_services"></a> [enabled\_services](#output\_enabled\_services) | List of enabled interface endpoint services |
| <a name="output_interface_endpoint_details"></a> [interface\_endpoint\_details](#output\_interface\_endpoint\_details) | Detailed information about all interface endpoints |
| <a name="output_interface_endpoint_dns_names"></a> [interface\_endpoint\_dns\_names](#output\_interface\_endpoint\_dns\_names) | Map of interface endpoint DNS names by service |
| <a name="output_interface_endpoints_security_group_id"></a> [interface\_endpoints\_security\_group\_id](#output\_interface\_endpoints\_security\_group\_id) | Security group ID for interface VPC endpoints |
| <a name="output_interface_vpc_endpoint_ids"></a> [interface\_vpc\_endpoint\_ids](#output\_interface\_vpc\_endpoint\_ids) | List of interface VPC endpoint IDs for security group associations |
<!-- END_TF_DOCS -->