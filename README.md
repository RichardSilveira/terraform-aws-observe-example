# AWS Network Foundation

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)

Production-grade Terraform module for building a secure, scalable, and highly available AWS network foundation. This module provides comprehensive networking infrastructure as a reusable foundation for other projects, featuring intelligent VPC endpoint management for 15+ AWS services.

## Overview

This networking foundation creates a complete AWS network infrastructure with proper security boundaries and private connectivity to AWS services. The module is designed to be deployed first as a prerequisite for application workloads, providing a secure and scalable network foundation.

## Key Capabilities

### 🏗️ **Core Network Infrastructure**

- **Multi-AZ VPC** with configurable CIDR blocks and DNS hostname support
- **6 Subnets** (3 public + 3 private) distributed across availability zones for high availability
- **Internet Gateway** for public subnet connectivity
- **NAT Gateway** with Elastic IP for secure private subnet internet access
- **Route Tables** with optimized routing for public and private traffic flows

### 🔒 **Security & Access Control**

- **Network ACLs** with granular subnet-level security rules
- **Security Groups** for VPC endpoint access with automatic HTTPS configuration
- **Private DNS** resolution for VPC endpoints

### 🔗 **Comprehensive VPC Endpoints**

Intelligent interface endpoint module supporting 15+ AWS services with simple boolean configuration:

- **Management Services**: SSM Session Manager, IAM, Secrets Manager
- **Messaging Services**: SQS, SNS, EventBridge
- **Compute Services**: Lambda
- **Monitoring Services**: CloudWatch (monitoring + logs)
- **Container Services**: ECR, ECS, EKS with automatic dependency management

### ⚙️ **Smart Configuration**

- **Service Dependencies**: ECS/EKS automatically includes ECR endpoints
- **Grouped Endpoints**: Related services (like SSM Session Manager) are configured together
- **Modular Design**: Reusable components for consistent infrastructure patterns
- **Environment Support**: Configurable for development, staging, and production environments

## Network Architecture

The module creates a secure, multi-tier network architecture:

```
┌─────────────────────────────────────────────────────┐
│                     VPC                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │   Public    │  │   Public    │  │   Public    │  │
│  │  Subnet 1   │  │  Subnet 2   │  │  Subnet 3   │  │
│  │     AZ-a    │  │     AZ-b    │  │     AZ-c    │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  │
│         │                 │                 │       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │   Private   │  │   Private   │  │   Private   │  │
│  │  Subnet 1   │  │  Subnet 2   │  │  Subnet 3   │  │
│  │     AZ-a    │  │     AZ-b    │  │     AZ-c    │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  │
│         │                 │                 │       │
│  ┌─────────────────────────────────────────────────┐ │
│  │            VPC Endpoints (15+ Services)         │ │
│  └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## Benefits

- **🚀 Rapid Deployment**: Complete network foundation in minutes
- **🔐 Enhanced Security**: Private connectivity to AWS services without internet routing
- **💰 Cost Optimization**: Reduced NAT Gateway costs through VPC endpoints
- **⚡ Improved Performance**: Lower latency through private AWS service access
- **🎯 Simplified Management**: Boolean flags for easy service endpoint configuration
- **📈 Scalable Foundation**: Ready for enterprise workloads and multi-account architectures

## Project Structure

```
iac/
├── networking.tf                    # Main networking configuration
├── modules/
│   └── networking-components/       # Core networking module
│       ├── main.tf                 # VPC and interface endpoints orchestration
│       ├── outputs.tf              # Networking resource outputs
│       └── modules/
│           ├── vpc/                # VPC, subnets, routing, NACLs
│           └── interface_endpoints/ # Configurable VPC endpoints for AWS services
```

## Module Outputs

The module provides comprehensive outputs for consuming projects:

- VPC ID and CIDR block information
- Public and private subnet IDs for resource deployment
- NAT Gateway and Internet Gateway IDs
- Interface endpoint details and DNS names
- Security group IDs for VPC endpoint access
- **🔒 Security-First Design**: Network ACLs, security groups, and private connectivity patterns
- **🌐 Comprehensive VPC Endpoints**: Support for 15+ AWS services with simple boolean configuration
- **⚡ High Availability**: Cross-AZ redundancy for critical networking components
- **🏷️ Consistent Tagging**: Standardized resource tagging for cost management and organization
- **📦 Modular Architecture**: Reusable components that can be consumed by other Terraform projects

## Architecture

> You can change the CIDR range as needed, this is just an example

```
┌─────────────────────────────────────────────────────────────┐
│                           VPC                               │
│                      10.0.0.0/16                           │
├─────────────────┬─────────────────┬─────────────────────────┤
│   AZ-a (us-east-1a)  │   AZ-b (us-east-1b)  │   AZ-c (us-east-1c)   │
├─────────────────┼─────────────────┼─────────────────────────┤
│ Public: 10.0.1.0/24  │ Public: 10.0.2.0/24  │ Public: 10.0.3.0/24   │
│ Private: 10.0.11.0/24│ Private: 10.0.12.0/24│ Private: 10.0.13.0/24 │
└─────────────────┴─────────────────┴─────────────────────────┘
            │                              │
        [NAT GW] ←──────────────────→ [Internet GW]
            │                              │
    [VPC Endpoints]                   [Public Access]
```

## Quick Start

### Basic Usage

```hcl
module "network_foundation" {
  source = "git::https://github.com/RichardSilveira/terraform-aws-network-foundation.git//iac?ref=main"

  # Project identification
  owner       = "your-email@company.com"
  project     = "my-project"
  environment = "dev"
  created_by  = "arn:aws:iam::123456789012:user/terraform-user"

  # Optional: Enable VPC endpoints for your services
  enable_ssm_session_manager = true  # For EC2 Session Manager
  enable_lambda             = true   # For Lambda functions
  enable_ecr                = true   # For container registries
}
```

### Advanced Configuration

```hcl
module "network_foundation" {
  source = "./iac"

  # Project metadata
  owner       = "devops-team@company.com"
  cost_center = "ENGINEERING"
  project     = "production-workloads"
  environment = "prod"
  created_by  = "arn:aws:iam::123456789012:role/TerraformRole"

  # Custom VPC configuration
  vpc_cidr_block = "10.100.0.0/16"

  # Production settings
  create_second_nat = true  # Enable for production environments

  # Enable comprehensive VPC endpoints
  enable_ssm_session_manager = true
  enable_ecs                = true  # Automatically includes ECR
  enable_lambda             = true
  enable_sns                = true
  enable_sqs                = true
  enable_secrets_manager    = true
  enable_cloudwatch         = true
}
```

## Technical Specifications

### Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

### Available Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | The ID of the VPC |
| `vpc_cidr_block` | The CIDR block of the VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `nat_gateway_ids` | List of NAT Gateway IDs |
| `internet_gateway_id` | The Internet Gateway ID |
| `interface_vpc_endpoint_ids` | List of VPC endpoint IDs |
| `interface_endpoints_security_group_id` | Security group ID for VPC endpoints |
| terraform | >= 1.0 |
| aws | ~> 5.0 |

