/*
  This file contains mock resources deployed in a SOURCE AWS account.
  These resources simulate a customer's existing infrastructure that needs
  to send logs to Observe via a cross-account CloudWatch Logs subscription.

  Architecture:
  - Mock Lambda Function (in source account) → CloudWatch Log Group (in source account)
  - CloudWatch Log Subscription Filter (in source account) → CloudWatch Logs Destination (in destination account)
  - CloudWatch Logs Destination (in destination account) → Kinesis Firehose → Observe
 */

# --------------------------------------------------
# Mock Lambda Function in Source Account
# --------------------------------------------------

# Lambda execution role
resource "aws_iam_role" "source_mock_lambda" {
  provider = aws.source_account
  name     = "${local.resource_prefix}-source-mock-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${local.resource_prefix}-source-mock-lambda-role"
  }
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "source_mock_lambda_basic" {
  provider   = aws.source_account
  role       = aws_iam_role.source_mock_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Log Group for the Lambda function
resource "aws_cloudwatch_log_group" "source_mock_lambda" {
  provider          = aws.source_account
  name              = "/aws/lambda/${local.resource_prefix}-source-mock-lambda"
  retention_in_days = 7

  tags = {
    Name = "${local.resource_prefix}-source-mock-lambda-logs"
  }
}

# Lambda function package
data "archive_file" "source_mock_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/builds/source_mock_lambda.zip"
  source {
    content  = <<EOF
import json
import logging
import random
import time
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Mock Lambda function that generates realistic application logs
    for cross-account CloudWatch Logs subscription testing.
    """
    start_time = time.time()
    request_id = context.aws_request_id

    # Simulate realistic application logging
    logger.info(f"[SOURCE ACCOUNT] Processing request {request_id}")
    logger.info(f"[SOURCE ACCOUNT] Event received: {json.dumps(event, default=str)}")
    logger.info(f"[SOURCE ACCOUNT] Function: {context.function_name}, Version: {context.function_version}")

    # Simulate some processing time
    processing_time = random.uniform(0.1, 0.5)
    time.sleep(processing_time)

    # Simulate different log levels and scenarios
    if random.random() < 0.15:  # 15% chance of warning
        logger.warning(f"[SOURCE ACCOUNT] Slow processing detected: {processing_time:.2f}s for request {request_id}")

    if random.random() < 0.05:  # 5% chance of error simulation
        logger.error(f"[SOURCE ACCOUNT] Simulated error condition in request {request_id}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'request_id': request_id,
                'timestamp': datetime.utcnow().isoformat(),
                'source': 'source-account-lambda'
            })
        }

    # Success case
    end_time = time.time()
    duration = end_time - start_time

    logger.info(f"[SOURCE ACCOUNT] Request {request_id} completed successfully in {duration:.3f}s")

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Request processed successfully',
            'request_id': request_id,
            'duration_ms': duration * 1000,
            'timestamp': datetime.utcnow().isoformat(),
            'source': 'source-account-lambda'
        })
    }
EOF
    filename = "index.py"
  }
}

# Lambda function
resource "aws_lambda_function" "source_mock_lambda" {
  provider         = aws.source_account
  filename         = data.archive_file.source_mock_lambda_zip.output_path
  function_name    = "${local.resource_prefix}-source-mock-lambda"
  role             = aws_iam_role.source_mock_lambda.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.source_mock_lambda_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = 60
  memory_size      = 256

  depends_on = [
    aws_cloudwatch_log_group.source_mock_lambda,
    aws_iam_role_policy_attachment.source_mock_lambda_basic
  ]

  tags = {
    Name = "${local.resource_prefix}-source-mock-lambda"
  }
}

# --------------------------------------------------
# IAM Role for CloudWatch Logs Subscription Filter
# --------------------------------------------------

# This role is REQUIRED when the destination policy uses AWS Organization paths.
# AWS requires this role for additional security validation when using org-based access control.
# The role itself doesn't need any permissions - it's used purely for identity validation.
resource "aws_iam_role" "source_cwl_subscription" {
  provider = aws.source_account
  name     = "${local.resource_prefix}-source-cwl-subscription-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "logs.${data.aws_region.source_account.name}.amazonaws.com" },
      Action    = "sts:AssumeRole",
      Condition = {
        StringLike = {
          "aws:SourceArn" = "arn:aws:logs:${data.aws_region.source_account.name}:${data.aws_caller_identity.source_account.account_id}:*"
        }
      }
    }]
  })

  tags = {
    Name = "${local.resource_prefix}-source-cwl-subscription-role"
  }
}

# This policy allows CloudWatch Logs to validate the subscription filter.
# For Organization-based destination policies, AWS validates that the source account
# belongs to the allowed organization paths.
resource "aws_iam_role_policy" "source_cwl_subscription" {
  provider = aws.source_account
  name     = "${local.resource_prefix}-source-cwl-subscription-policy"
  role     = aws_iam_role.source_cwl_subscription.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${data.aws_region.source_account.name}:${data.aws_caller_identity.source_account.account_id}:log-group:*:*"
      }
    ]
  })
}

# --------------------------------------------------
# CloudWatch Logs Subscription Filter (Source Account)
# --------------------------------------------------

# This subscription filter sends logs from the source account's log group
# to the destination account's CloudWatch Logs destination.
#
# IMPORTANT: The role_arn IS required when the destination policy uses AWS Organization
# paths for access control. AWS uses this role to validate that the source account
# belongs to the allowed organization paths specified in the destination policy.
# See error: "Role ARN is required when creating subscription filter against destination
# with Organization access policy."
resource "aws_cloudwatch_log_subscription_filter" "source_to_destination" {
  provider        = aws.source_account
  name            = "${local.resource_prefix}-to-observe-destination"
  log_group_name  = aws_cloudwatch_log_group.source_mock_lambda.name
  filter_pattern  = "" # Forward all logs
  destination_arn = aws_cloudwatch_log_destination.to_firehose.arn
  role_arn        = aws_iam_role.source_cwl_subscription.arn

  depends_on = [
    time_sleep.wait_for_iam_role_propagation
  ]
}

# Wait for IAM role to propagate before creating subscription filter
# AWS needs time to validate that CloudWatch Logs can assume the role
resource "time_sleep" "wait_for_iam_role_propagation" {
  create_duration = "30s"

  depends_on = [
    aws_iam_role.source_cwl_subscription,
  ]
}
