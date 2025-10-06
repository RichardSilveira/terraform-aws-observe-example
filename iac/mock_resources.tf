/*
  This file contains mock resources that simulate real production workloads
  and generate logs/data that will be consumed by the Observe platform.
  These resources mimic realistic scenarios for testing and demonstration.
 */

# ---------------------
# Mock Lambda Function
# ---------------------

resource "aws_security_group" "mock_lambda" {
  name        = "${local.resource_prefix}-mock-lambda-sg"
  description = "Security group for Mock Lambda"
  vpc_id      = module.networking.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }

  tags = local.default_tags
}


module "mock_lambda" {
  source          = "./modules/lambda"
  resource_prefix = local.resource_prefix
  function_name   = "mock-lambda-function"
  description     = "A mock Lambda function that simulates application logs"
  source_path     = data.archive_file.mock_lambda_zip.output_path
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 60
  memory_size     = 512

  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [aws_security_group.mock_lambda.id]
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
  # tags   = local.default_tags
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

  lifecycle {
    ignore_changes = [content]
  }
}

resource "local_file" "sample_error_log" {
  content = templatefile("${path.module}/templates/sample_error.log.tpl", {
    timestamp = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
    app_name  = "mock-api-service"
    region    = local.region
  })
  filename = "${path.module}/generated_logs/sample_error.log"

  lifecycle {
    ignore_changes = [content]
  }
}

resource "local_file" "sample_access_log" {
  content = templatefile("${path.module}/templates/sample_access.log.tpl", {
    timestamp = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
  })
  filename = "${path.module}/generated_logs/sample_access.log"

  lifecycle {
    ignore_changes = [content]
  }
}

# Upload generated log files to S3
resource "aws_s3_object" "app_log" {
  bucket = aws_s3_bucket.mock_log_storage.id
  key    = "application-logs/${formatdate("YYYY/MM/DD", timestamp())}/app.log"
  source = local_file.sample_app_log.filename
  etag   = local_file.sample_app_log.content_md5
  tags   = local.default_tags

  lifecycle {
    ignore_changes = [source, key, etag] # remove key if you want to generate new files
  }
}

resource "aws_s3_object" "error_log" {
  bucket = aws_s3_bucket.mock_log_storage.id
  key    = "error-logs/${formatdate("YYYY/MM/DD", timestamp())}/error.log"
  source = local_file.sample_error_log.filename
  etag   = local_file.sample_error_log.content_md5
  tags   = local.default_tags

  lifecycle {
    ignore_changes = [source, key, etag] # remove key if you want to generate new files
  }
}

resource "aws_s3_object" "access_log" {
  bucket = aws_s3_bucket.mock_log_storage.id
  key    = "access-logs/${formatdate("YYYY/MM/DD", timestamp())}/access.log"
  source = local_file.sample_access_log.filename
  etag   = local_file.sample_access_log.content_md5
  tags   = local.default_tags

  lifecycle {
    ignore_changes = [source, key, etag] # remove key if you want to generate new files
  }
}
