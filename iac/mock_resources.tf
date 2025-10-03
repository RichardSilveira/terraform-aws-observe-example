/*
  This file contains mock resources that simulate real production workloads
  and generate logs/data that will be consumed by the Observe platform.
  These resources mimic realistic scenarios for testing and demonstration.
 */

# ------------------------------------------
# Mock Lambda Function with CloudWatch Logs
# ------------------------------------------

resource "aws_lambda_function" "mock_app" {
  filename      = "mock_lambda.zip"
  function_name = "${local.resource_prefix}-mock-app-lambda"
  role          = aws_iam_role.mock_lambda_execution.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 60

  # Create a simple dummy zip file if it doesn't exist
  depends_on = [data.archive_file.mock_lambda_zip]

  tags = local.default_tags
}

resource "aws_iam_role" "mock_lambda_execution" {
  name = "${local.resource_prefix}-mock-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "mock_lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.mock_lambda_execution.name
}

resource "aws_cloudwatch_log_group" "mock_app_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.mock_app.function_name}"
  retention_in_days = local.cloudwatch_log_retention_days

  tags = local.default_tags
}

# CloudWatch Logs Subscription Filter to forward logs to Observe
resource "aws_cloudwatch_log_subscription_filter" "mock_lambda_to_observe" {
  name            = "${local.resource_prefix}-mock-lambda-to-observe"
  log_group_name  = aws_cloudwatch_log_group.mock_app_lambda.name
  filter_pattern  = "" # Forward all logs
  destination_arn = aws_cloudwatch_log_destination.to_firehose.arn

  depends_on = [aws_cloudwatch_log_destination_policy.to_firehose]
}

# Create a mock Lambda ZIP file with realistic logging
data "archive_file" "mock_lambda_zip" {
  type        = "zip"
  output_path = "mock_lambda.zip"
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
    start_time = time.time()
    request_id = context.aws_request_id

    # Simulate realistic application logging
    logger.info(f"Processing request {request_id}")
    logger.info(f"Event received: {json.dumps(event, default=str)}")

    # Simulate some processing time
    processing_time = random.uniform(0.1, 0.5)
    time.sleep(processing_time)

    # Simulate different log levels and scenarios
    if random.random() < 0.1:  # 10% chance of warning
        logger.warning(f"Slow processing detected: {processing_time:.2f}s")

    if random.random() < 0.05:  # 5% chance of error simulation
        logger.error(f"Simulated error condition in request {request_id}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'request_id': request_id,
                'timestamp': datetime.utcnow().isoformat()
            })
        }

    # Success case
    end_time = time.time()
    duration = end_time - start_time

    logger.info(f"Request {request_id} completed successfully in {duration:.3f}s")

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Mock application processed successfully',
            'request_id': request_id,
            'processing_time': f"{duration:.3f}s",
            'timestamp': datetime.utcnow().isoformat(),
            'event_summary': {
                'source': event.get('source', 'unknown'),
                'detail_type': event.get('detail-type', 'unknown')
            }
        })
    }
EOF
    filename = "index.py"
  }
}

# todo - Instead of a data storage workload, I want to simulate log entries (e.g., application logs) but I'm not sure how to do that. I want the simplest possible thing that generates logs that can be forwarded to Observe. Ex. Maybe you could simply generate log files (mock) and store them in a file here that will upload a few once I run terraform apply

# --------------------------------------------------
# Mock S3 Bucket (simulating data storage workload)
# --------------------------------------------------
# This S3 bucket simulates a real data storage workload that might exist
# in production. It represents typical data sources that could be monitored.

resource "aws_s3_bucket" "mock_data_storage" {
  bucket = "${local.resource_prefix}-mock-data-storage"
  tags   = local.default_tags
}

# todo - review all comments as this one from below that explain the purpose of the resource that are obvious and remove them. Only those kind of comments.
# Configure versioning for the mock bucket
resource "aws_s3_bucket_versioning" "mock_data_storage" {
  bucket = aws_s3_bucket.mock_data_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}
# todo - review if by default versioning is disabled. If so, remove aws_s3_bucket_versioning.mock_data_storage resource. Same for other S3 related resource blocks

# Configure server-side encryption for the mock bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "mock_data_storage" {
  bucket = aws_s3_bucket.mock_data_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access for security
resource "aws_s3_bucket_public_access_block" "mock_data_storage" {
  bucket = aws_s3_bucket.mock_data_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
