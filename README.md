# Terraform AWS Observe Example

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)

This repository provides a minimal Terraform example that demonstrates how to forward AWS data into Observe. While the initial focus is on CloudWatch Log subscriptions (to an Observe Lambda forwarder) and S3 bucket event ingestion (via Observe’s Lambda or Filedrop approach), the project is designed to evolve and include other integration patterns over time. It shows end-to-end wiring of permissions, IAM roles, triggers, and configuration so you can use it as a template or reference when integrating your AWS workloads with Observe’s ingest pipeline.
