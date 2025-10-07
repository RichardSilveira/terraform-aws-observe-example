<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~>2.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~>5.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~>2.4 |
| <a name="requirement_observe"></a> [observe](#requirement\_observe) | ~>0.13 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.7.1 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.5.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_mock_lambda"></a> [mock\_lambda](#module\_mock\_lambda) | ./modules/lambda | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking-components | n/a |
| <a name="module_observe_filedrop"></a> [observe\_filedrop](#module\_observe\_filedrop) | observeinc/collection/aws//modules/forwarder | >= 2.10 |
| <a name="module_observe_kinesis_firehose"></a> [observe\_kinesis\_firehose](#module\_observe\_kinesis\_firehose) | observeinc/kinesis-firehose/aws | 2.4.1 |
| <a name="module_observe_s3_bucket_subscription"></a> [observe\_s3\_bucket\_subscription](#module\_observe\_s3\_bucket\_subscription) | observeinc/lambda/aws//modules/s3_bucket_subscription | 3.6.0 |
| <a name="module_observe_s3_forwarder_lambda"></a> [observe\_s3\_forwarder\_lambda](#module\_observe\_s3\_forwarder\_lambda) | observeinc/lambda/aws | 3.6.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_destination.to_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_destination) | resource |
| [aws_cloudwatch_log_destination_policy.to_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_destination_policy) | resource |
| [aws_cloudwatch_log_group.firehose_cwl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_subscription_filter.mock_lambda_to_observe](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) | resource |
| [aws_iam_role.cwl_direct_to_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.to_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cwl_direct_to_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.to_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket.mock_log_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.mock_log_storage_filedrop](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.observe_firehose_failed_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_notification.to_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_public_access_block.mock_log_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.mock_log_storage_filedrop](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.observe_firehose_failed_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_object.access_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.access_log_filedrop](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.app_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.app_log_filedrop](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.error_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.error_log_filedrop](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_security_group.mock_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.observe_s3_forwarder_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [local_file.sample_access_log](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.sample_access_log_filedrop](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.sample_app_log](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.sample_app_log_filedrop](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.sample_error_log](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.sample_error_log_filedrop](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [archive_file.mock_lambda_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS CLI profile to use | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | `null` | no |
| <a name="input_cost_center"></a> [cost\_center](#input\_cost\_center) | The cost center associated with the resources. | `string` | `null` | no |
| <a name="input_created_by"></a> [created\_by](#input\_created\_by) | The arn of the IAM user or role that create the resources | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment for the resources (e.g., dev, staging, prod). | `string` | n/a | yes |
| <a name="input_observe_collection_endpoint"></a> [observe\_collection\_endpoint](#input\_observe\_collection\_endpoint) | Observe collection endpoint, e.g. https://123456789012.collect.observeinc.com (us-west-2) or https://123456789012.collect.us-east-1.observeinc.com per Observe docs | `string` | n/a | yes |
| <a name="input_observe_customer"></a> [observe\_customer](#input\_observe\_customer) | Observe Customer ID | `string` | n/a | yes |
| <a name="input_observe_filedrop_access_point_arn"></a> [observe\_filedrop\_access\_point\_arn](#input\_observe\_filedrop\_access\_point\_arn) | Observe Filedrop S3 Access Point ARN | `string` | `""` | no |
| <a name="input_observe_filedrop_bucket"></a> [observe\_filedrop\_bucket](#input\_observe\_filedrop\_bucket) | Observe Filedrop S3 bucket name | `string` | `""` | no |
| <a name="input_observe_filedrop_bucket_prefix"></a> [observe\_filedrop\_bucket\_prefix](#input\_observe\_filedrop\_bucket\_prefix) | Observe Filedrop S3 bucket prefix | `string` | `""` | no |
| <a name="input_observe_token"></a> [observe\_token](#input\_observe\_token) | Observe authentication token | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | The owner of the resources. | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The project name for the resources. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_enabled_interface_endpoint_services"></a> [enabled\_interface\_endpoint\_services](#output\_enabled\_interface\_endpoint\_services) | List of enabled interface endpoint services |
| <a name="output_interface_endpoint_details"></a> [interface\_endpoint\_details](#output\_interface\_endpoint\_details) | Detailed information about all interface endpoints |
| <a name="output_interface_endpoint_dns_names"></a> [interface\_endpoint\_dns\_names](#output\_interface\_endpoint\_dns\_names) | Map of interface endpoint DNS names by service |
| <a name="output_interface_endpoints_security_group_id"></a> [interface\_endpoints\_security\_group\_id](#output\_interface\_endpoints\_security\_group\_id) | Security group ID for interface VPC endpoints |
| <a name="output_interface_vpc_endpoint_ids"></a> [interface\_vpc\_endpoint\_ids](#output\_interface\_vpc\_endpoint\_ids) | List of interface VPC endpoint IDs for security group associations |
| <a name="output_internet_gateway_id"></a> [internet\_gateway\_id](#output\_internet\_gateway\_id) | The ID of the Internet Gateway |
| <a name="output_mock_lambda_function_arn"></a> [mock\_lambda\_function\_arn](#output\_mock\_lambda\_function\_arn) | ARN of the mock Lambda function |
| <a name="output_mock_lambda_function_name"></a> [mock\_lambda\_function\_name](#output\_mock\_lambda\_function\_name) | Name of the mock Lambda function |
| <a name="output_mock_s3_log_bucket_arn"></a> [mock\_s3\_log\_bucket\_arn](#output\_mock\_s3\_log\_bucket\_arn) | ARN of the mock S3 log storage bucket |
| <a name="output_mock_s3_log_bucket_name"></a> [mock\_s3\_log\_bucket\_name](#output\_mock\_s3\_log\_bucket\_name) | Name of the mock S3 log storage bucket |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | The IDs of the NAT Gateways |
| <a name="output_observe_cloudwatch_destination_arn"></a> [observe\_cloudwatch\_destination\_arn](#output\_observe\_cloudwatch\_destination\_arn) | ARN of the CloudWatch Logs destination for Observe |
| <a name="output_observe_cloudwatch_destination_name"></a> [observe\_cloudwatch\_destination\_name](#output\_observe\_cloudwatch\_destination\_name) | Name of the CloudWatch Logs destination for Observe |
| <a name="output_observe_firehose_arn"></a> [observe\_firehose\_arn](#output\_observe\_firehose\_arn) | ARN of the Observe Kinesis Firehose delivery stream |
| <a name="output_observe_firehose_name"></a> [observe\_firehose\_name](#output\_observe\_firehose\_name) | Name of the Observe Kinesis Firehose delivery stream |
| <a name="output_observe_s3_backup_bucket"></a> [observe\_s3\_backup\_bucket](#output\_observe\_s3\_backup\_bucket) | S3 bucket used for Observe Firehose failed events backup |
| <a name="output_observe_s3_forwarder_lambda_name"></a> [observe\_s3\_forwarder\_lambda\_name](#output\_observe\_s3\_forwarder\_lambda\_name) | Name of the Observe S3 forwarder Lambda function |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | The IDs of the private subnets |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | The IDs of the public subnets |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
<!-- END_TF_DOCS -->