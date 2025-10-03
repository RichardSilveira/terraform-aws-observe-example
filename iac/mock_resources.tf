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
  name = "/aws/lambda/${aws_lambda_function.mock_app.function_name}"

  tags = local.default_tags
}

# CloudWatch Logs subscription filter (same-account) sending directly to Firehose
# For cross-account or org-level aggregation, use a CloudWatch Logs Destination instead.
resource "aws_cloudwatch_log_subscription_filter" "mock_lambda_to_observe" {
  name           = "${local.resource_prefix}-mock-lambda-to-observe"
  log_group_name = aws_cloudwatch_log_group.mock_app_lambda.name
  filter_pattern = "" # Forward all logs

  destination_arn = module.observe_kinesis_firehose.firehose_delivery_stream.arn
  role_arn        = aws_iam_role.cwl_direct_to_firehose.arn
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

# --------------------------------------------------
# Mock S3 Log Storage and Generation
# --------------------------------------------------
# This system generates sample log files and uploads them to S3
# to simulate real application logs that could be processed by Observe

resource "aws_s3_bucket" "mock_log_storage" {
  bucket = "${local.resource_prefix}-mock-log-storage"
  tags   = local.default_tags
}

resource "aws_s3_bucket_public_access_block" "mock_log_storage" {
  bucket = aws_s3_bucket.mock_log_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Generate sample application log files
resource "local_file" "sample_app_log" {
  content = templatefile("${path.module}/templates/sample_app.log.tpl", {
    timestamp = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
    app_name  = "mock-web-app"
    region    = local.region
  })
  filename = "${path.module}/generated_logs/sample_app.log"
}

resource "local_file" "sample_error_log" {
  content = templatefile("${path.module}/templates/sample_error.log.tpl", {
    timestamp = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
    app_name  = "mock-api-service"
    region    = local.region
  })
  filename = "${path.module}/generated_logs/sample_error.log"
}

resource "local_file" "sample_access_log" {
  content = templatefile("${path.module}/templates/sample_access.log.tpl", {
    timestamp = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
  })
  filename = "${path.module}/generated_logs/sample_access.log"
}

# Upload generated log files to S3
resource "aws_s3_object" "app_log" {
  bucket = aws_s3_bucket.mock_log_storage.id
  key    = "application-logs/${formatdate("YYYY/MM/DD", timestamp())}/app.log"
  source = local_file.sample_app_log.filename
  etag   = local_file.sample_app_log.content_md5

  tags = local.default_tags
}

resource "aws_s3_object" "error_log" {
  bucket = aws_s3_bucket.mock_log_storage.id
  key    = "error-logs/${formatdate("YYYY/MM/DD", timestamp())}/error.log"
  source = local_file.sample_error_log.filename
  etag   = local_file.sample_error_log.content_md5

  tags = local.default_tags
}

resource "aws_s3_object" "access_log" {
  bucket = aws_s3_bucket.mock_log_storage.id
  key    = "access-logs/${formatdate("YYYY/MM/DD", timestamp())}/access.log"
  source = local_file.sample_access_log.filename
  etag   = local_file.sample_access_log.content_md5

  tags = local.default_tags
}
