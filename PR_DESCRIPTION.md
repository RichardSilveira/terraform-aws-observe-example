# feat: Add AWS Network Foundation Infrastructure

## Overview
This PR introduces a comprehensive AWS Network Foundation module that provides production-ready networking infrastructure as a reusable foundation for other projects. The module creates a secure, multi-AZ VPC environment with proper segmentation between public and private networks.

The foundation includes a powerful interface endpoints module that can provision VPC endpoints for virtually any AWS service with simple boolean flags. This enables secure, private connectivity to AWS services without internet routing, reducing latency and improving security. The module intelligently handles service dependencies (e.g., ECS/EKS automatically includes ECR endpoints) and groups related endpoints for simplified configuration.

## Networking Resources Created
- **VPC** with configurable CIDR (`10.0.0.0/16`) and DNS hostnames enabled
- **6 Subnets** across 3 AZs (3 public + 3 private) for high availability
- **Internet Gateway** for public subnet internet access
- **NAT Gateway** for secure private subnet internet connectivity
- **Route Tables** with proper routing configuration for public/private traffic
- **Network ACLs** with granular security rules for subnet-level protection
- **Interface VPC Endpoints Module** supporting 15+ AWS services:
  - **Management**: SSM Session Manager (3 endpoints), IAM, Secrets Manager
  - **Messaging**: SQS, SNS, EventBridge
  - **Compute**: Lambda
  - **Monitoring**: CloudWatch (monitoring + logs)
  - **Containers**: ECR (API + Docker), ECS (3 endpoints), EKS (2 endpoints)
- **Security Groups** for VPC endpoint access control with automatic HTTPS configuration
- **Elastic IP** for NAT Gateway static addressing
