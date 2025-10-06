# Networking Components

This module creates a complete AWS networking infrastructure for secure application deployment. It provisions a VPC with public and private subnets across multiple availability zones, NAT gateways for outbound internet access from private subnets, and an internet gateway for public subnet connectivity. The module also implements network ACLs with separate rule sets for public subnets (allowing HTTP/HTTPS ingress and ephemeral ports) and private subnets (restricting direct internet access while allowing VPC traffic).

The module supports flexible configuration including optional third AZ deployment and configurable NAT gateway redundancy. All networking components are properly tagged and follow AWS best practices for security and availability.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_interface_endpoints"></a> [interface\_endpoints](#module\_interface\_endpoints) | ./modules/interface_endpoints | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./modules/vpc | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_interface_endpoints_config"></a> [interface\_endpoints\_config](#input\_interface\_endpoints\_config) | Interface VPC Endpoints Configuration. | <pre>object({<br/>    name = string<br/><br/>    # Service-specific endpoint options (grouped by functionality)<br/>    enable_ssm_session_manager = optional(bool, false) # Includes: ssm, ec2messages, ssmmessages<br/>    enable_sqs                 = optional(bool, false)<br/>    enable_sns                 = optional(bool, false)<br/>    enable_eventbridge         = optional(bool, false)<br/>    enable_lambda              = optional(bool, false)<br/>    enable_secrets_manager     = optional(bool, false)<br/>    enable_iam                 = optional(bool, false)<br/>    enable_cloudwatch          = optional(bool, false) # Includes: monitoring, logs<br/><br/>    # Container services (ECR auto-included with ECS/EKS)<br/>    enable_ecr = optional(bool, false) # Standalone for EC2 Docker usage<br/>    enable_ecs = optional(bool, false) # Includes: ecs, ecs-agent, ecs-telemetry + ECR<br/>    enable_eks = optional(bool, false) # Includes: eks, eks-auth + ECR<br/>  })</pre> | <pre>{<br/>  "enable_cloudwatch": false,<br/>  "enable_ecr": false,<br/>  "enable_ecs": false,<br/>  "enable_eks": false,<br/>  "enable_eventbridge": false,<br/>  "enable_iam": false,<br/>  "enable_lambda": false,<br/>  "enable_secrets_manager": false,<br/>  "enable_sns": false,<br/>  "enable_sqs": false,<br/>  "enable_ssm_session_manager": false,<br/>  "name": "no-interface-endpoints"<br/>}</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for VPC endpoints. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | VPC Configuration. | <pre>object({<br/>    name                     = string<br/>    cidr_block               = string<br/>    public_subnet_1_cidr     = string<br/>    public_subnet_1_az       = string<br/>    public_subnet_2_cidr     = string<br/>    public_subnet_2_az       = string<br/>    public_subnet_3_cidr     = optional(string)<br/>    public_subnet_3_az       = optional(string)<br/>    private_subnet_1_cidr    = string<br/>    private_subnet_1_az      = string<br/>    private_subnet_2_cidr    = string<br/>    private_subnet_2_az      = string<br/>    private_subnet_3_cidr    = optional(string)<br/>    private_subnet_3_az      = optional(string)<br/>    create_second_nat        = optional(bool, true)<br/>    vpc_enable_dns_hostnames = optional(bool, true)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_enabled_interface_endpoint_services"></a> [enabled\_interface\_endpoint\_services](#output\_enabled\_interface\_endpoint\_services) | List of enabled interface endpoint services |
| <a name="output_interface_endpoint_details"></a> [interface\_endpoint\_details](#output\_interface\_endpoint\_details) | Detailed information about all interface endpoints |
| <a name="output_interface_endpoint_dns_names"></a> [interface\_endpoint\_dns\_names](#output\_interface\_endpoint\_dns\_names) | Map of interface endpoint DNS names by service |
| <a name="output_interface_endpoints_security_group_id"></a> [interface\_endpoints\_security\_group\_id](#output\_interface\_endpoints\_security\_group\_id) | Security group ID for interface VPC endpoints |
| <a name="output_interface_vpc_endpoint_ids"></a> [interface\_vpc\_endpoint\_ids](#output\_interface\_vpc\_endpoint\_ids) | List of interface VPC endpoint IDs for security group associations |
| <a name="output_internet_gateway_id"></a> [internet\_gateway\_id](#output\_internet\_gateway\_id) | The ID of the Internet Gateway |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | The IDs of the NAT Gateways |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | The IDs of the private subnets |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | The IDs of the public subnets |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | The name of the VPC |
<!-- END_TF_DOCS -->
