# Cross-Account CloudWatch Logs Forwarding to Observe

This document explains the cross-account CloudWatch Logs forwarding setup for sending logs from one AWS account (source) to another AWS account (destination), which then forwards to Observe via Kinesis Firehose.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Source AWS Account                                                          │
│                                                                             │
│  ┌──────────────────┐      ┌────────────────────────────────────┐          │
│  │  Lambda Function │ ───> │  CloudWatch Log Group              │          │
│  └──────────────────┘      └────────────────────────────────────┘          │
│                                            │                                │
│                                            │                                │
│                            ┌───────────────▼────────────────────┐          │
│                            │  CloudWatch Log Subscription Filter│          │
│                            │  (with IAM Role)                    │          │
│                            └───────────────┬────────────────────┘          │
└────────────────────────────────────────────┼────────────────────────────────┘
                                             │
                                             │ Cross-Account
                                             │ Log Stream
                                             │
┌────────────────────────────────────────────▼────────────────────────────────┐
│ Destination AWS Account                                                     │
│                                                                             │
│                 ┌──────────────────────────────────────┐                    │
│                 │  CloudWatch Logs Destination         │                    │
│                 │  (with Destination Policy)           │                    │
│                 └──────────────────┬───────────────────┘                    │
│                                    │                                        │
│                                    │                                        │
│                    ┌───────────────▼──────────────┐                         │
│                    │  Kinesis Firehose            │                         │
│                    │  Delivery Stream             │                         │
│                    └───────────────┬──────────────┘                         │
│                                    │                                        │
│                                    │ HTTPS                                  │
└────────────────────────────────────┼────────────────────────────────────────┘
                                     │
                                     │
                            ┌────────▼─────────┐
                            │  Observe         │
                            │  Platform        │
                            └──────────────────┘
```

## Components

### Source Account Resources

1. **Mock Lambda Function** (`aws_lambda_function.source_mock_lambda`)
   - Simulates a customer's existing application
   - Generates realistic application logs
   - Logs are written to CloudWatch Logs

2. **CloudWatch Log Group** (`aws_cloudwatch_log_group.source_mock_lambda`)
   - Captures logs from the Lambda function
   - Retention set to 7 days

3. **IAM Role for Subscription Filter** (`aws_iam_role.source_cwl_subscription`)
   - Assumed by CloudWatch Logs service
   - **REQUIRED** when destination policy uses AWS Organization paths for access control
   - AWS uses this role to validate that the source account belongs to allowed organization paths
   - Minimal required permissions:
     - `logs:PutLogEvents` (for basic CloudWatch Logs functionality)
   - Includes condition key `aws:SourceArn` to prevent confused deputy attacks

4. **CloudWatch Log Subscription Filter** (`aws_cloudwatch_log_subscription_filter.source_to_destination`)
   - Forwards all logs (empty filter pattern) from the log group
   - Points to the CloudWatch Logs Destination in the destination account
   - **Must include `role_arn`** when destination uses Organization-based access control

### Destination Account Resources

1. **CloudWatch Logs Destination** (`aws_cloudwatch_log_destination.to_firehose`)
   - Named entry point for cross-account log subscriptions
   - Points to the Kinesis Firehose delivery stream
   - Uses an IAM role to write to Firehose

2. **CloudWatch Logs Destination Policy** (`aws_cloudwatch_log_destination_policy.to_firehose`)
   - Resource policy that controls which accounts can send logs
   - Supports two modes:
     - **Organization-based**: Restricts access using AWS Organization paths (recommended)
     - **Open**: Allows any account (when `cross_account_org_paths` is empty)

3. **IAM Role for Destination** (`aws_iam_role.to_firehose`)
   - Assumed by CloudWatch Logs service
   - Allows writing to the Kinesis Firehose delivery stream
   - Permissions:
     - `firehose:PutRecord`
     - `firehose:PutRecordBatch`

4. **Kinesis Firehose Delivery Stream** (`module.observe_kinesis_firehose`)
   - Receives logs from the CloudWatch Logs Destination
   - Transforms and buffers log data
   - Forwards to Observe HTTP endpoint

## Configuration

### Prerequisites

- Two AWS accounts (or one account with different profiles for testing)
- AWS CLI configured with profiles for both accounts
- Observe platform credentials (customer ID, token, collection endpoint)
- (Optional) AWS Organization ID and path for access control

### Variables

Add these variables to your `local.auto.tfvars`:

```hcl
# Source account configuration
source_account_profile = "your-source-account-profile"
source_account_region  = "us-east-1"  # Optional, defaults to aws_region

# Optional: Restrict access to specific AWS Organization paths
cross_account_org_paths = [
  "o-yourorgid/r-rootid/o-yourorgid/*"
]
```

### Variable Descriptions

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `source_account_profile` | AWS CLI profile for the source account | No | `null` |
| `source_account_region` | AWS region for source account resources | No | Same as `aws_region` |
| `cross_account_org_paths` | List of AWS Organization paths allowed to send logs | No | `[]` (allows all) |

## IAM Permissions Required

### Source Account

The IAM user/role running Terraform needs:
- Full Lambda permissions (create/update/delete functions)
- CloudWatch Logs permissions (create/update/delete log groups, subscription filters)
- IAM permissions (create/update/delete roles and policies)

### Destination Account

The IAM user/role running Terraform needs:
- CloudWatch Logs destination permissions
- Kinesis Firehose permissions
- IAM permissions (create/update/delete roles and policies)
- S3 permissions (for Firehose backup bucket)

## Security Considerations

### AWS Organization Path-Based Access Control

When using `cross_account_org_paths`, the destination policy restricts access to only those accounts within the specified organization paths. This is the recommended approach for production environments.

**IMPORTANT**: When using Organization-based access control, AWS **requires** an IAM role in the subscription filter. This is a security requirement - AWS uses the role to validate that the source account belongs to the allowed organization paths. The error you'll see without it is: `"Role ARN is required when creating subscription filter against destination with Organization access policy."`

Example organization path structure:
```
o-abc123xyz45/          # Organization ID
  r-root123/            # Root ID
    ou-dept-12345678/   # Organizational Unit
      123456789012      # Account ID
```

To allow all accounts in your organization:
```hcl
cross_account_org_paths = ["o-abc123xyz45/*/*"]
```

To allow specific OUs:
```hcl
cross_account_org_paths = [
  "o-abc123xyz45/r-root123/ou-dept-12345678/*",
  "o-abc123xyz45/r-root123/ou-prod-87654321/*"
]
```

### Open Access (Testing Only)

If `cross_account_org_paths` is empty or not set, the destination policy allows any AWS account to create subscription filters. **This should only be used for testing.**

## Testing the Setup

### 1. Deploy the Infrastructure

```bash
cd iac/
terraform init
terraform plan -out=tfplan | tee tfplan.log
# Review the plan
terraform apply tfplan
```

### 2. Invoke the Source Lambda

You can invoke the Lambda function to generate logs:

```bash
# Using AWS CLI with source account profile
aws lambda invoke \
  --profile your-source-account-profile \
  --function-name <source_lambda_name> \
  --payload '{"test": "event"}' \
  response.json

# Check the response
cat response.json
```

### 3. Verify Log Flow

1. **Check CloudWatch Logs in Source Account**
   - Navigate to CloudWatch Logs in the source account
   - Find the log group: `/aws/lambda/<resource-prefix>-source-mock-lambda`
   - Verify logs are being created

2. **Verify Subscription Filter**
   - In the log group, check the "Subscription filters" tab
   - Confirm the filter points to the destination account

3. **Monitor Firehose in Destination Account**
   - Navigate to Kinesis Data Firehose in the destination account
   - Check metrics for incoming records
   - Look for any delivery errors

4. **Check Observe Platform**
   - Log into Observe
   - Navigate to your data streams
   - Search for logs with `source: source-account-lambda`
   - Verify logs are arriving with proper timestamps

### 4. Check for Errors

**CloudWatch Logs Errors (Source Account)**:
```bash
aws logs describe-subscription-filters \
  --profile your-source-account-profile \
  --log-group-name /aws/lambda/<function-name>
```

**Firehose Errors (Destination Account)**:
```bash
aws firehose describe-delivery-stream \
  --profile your-destination-account-profile \
  --delivery-stream-name <firehose-name>
```

## Troubleshooting

### Common Issues

1. **"Access Denied" when creating subscription filter**
   - Verify the destination policy allows the source account
   - Check that the organization path in the policy matches your account's org path
   - Ensure the IAM role in the source account has `logs:PutSubscriptionFilter` permission

2. **Logs not appearing in Firehose**
   - Check CloudWatch Logs metrics in the destination account
   - Verify the destination's IAM role has permissions to write to Firehose
   - Check Firehose CloudWatch Logs for errors

3. **Logs not reaching Observe**
   - Verify Observe credentials are correct
   - Check Firehose delivery errors in the S3 backup bucket
   - Ensure the Observe HTTP endpoint is reachable from your AWS region

4. **Provider configuration errors**
   - Ensure both AWS profiles are properly configured in `~/.aws/credentials`
   - Verify the source account profile has valid credentials
   - Check that the region is correctly set

### Debug Commands

```bash
# Test source account connectivity
aws sts get-caller-identity --profile your-source-account-profile

# Test destination account connectivity
aws sts get-caller-identity --profile your-destination-account-profile

# Check CloudWatch Logs destination
aws logs describe-destinations \
  --profile your-destination-account-profile \
  --region us-east-1

# Get organization information
aws organizations describe-organization
aws organizations list-accounts
```

## Cost Considerations

- **CloudWatch Logs**: Charged for data ingestion and storage
- **CloudWatch Logs Data Transfer**: Cross-account data transfer charges may apply
- **Kinesis Firehose**: Charged per GB of data ingested
- **Lambda Invocations**: Charged per invocation and duration
- **S3 Storage**: For Firehose backup/failed events

## Cleanup

To remove all cross-account resources:

```bash
terraform destroy
```

This will remove:
- Source account Lambda function and log group
- Subscription filter
- All IAM roles and policies
- CloudWatch Logs destination (destination account)
- Kinesis Firehose (if no other dependencies)

## References

- [AWS CloudWatch Logs Cross-Account Subscriptions](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CrossAccountSubscriptions-Firehose-Account.html)
- [CloudWatch Logs Subscription Filters](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/SubscriptionFilters.html)
- [Observe Data Ingestion Documentation](https://docs.observeinc.com/)
- [AWS Organizations](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html)
