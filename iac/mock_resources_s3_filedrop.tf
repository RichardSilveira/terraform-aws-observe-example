/*
  This file contains mock resources that simulate real production workloads
  and generate logs/data that will be consumed by the Observe platform.
  These resources mimic realistic scenarios for testing and demonstration for Filedrop.
 */


# --------------------------------------------------
# Mock S3 Log Storage and Generation
# --------------------------------------------------
# This system generates sample log files and uploads them to S3
# to simulate real application logs that could be processed by Observe

resource "aws_s3_bucket" "mock_log_storage_filedrop" {
  bucket = "${local.resource_prefix}-mock-log-storage-filedrop"
}

resource "aws_s3_bucket_public_access_block" "mock_log_storage_filedrop" {
  bucket = aws_s3_bucket.mock_log_storage_filedrop.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Generate sample application log files
resource "local_file" "sample_app_log_filedrop" {
  content = templatefile("${path.module}/templates/sample_app.log.tpl", {
    timestamp = local.static_log_timestamp
    app_name  = "mock-web-app"
    region    = local.region
  })
  filename = "${path.module}/generated_logs/sample_app.log"
}

resource "local_file" "sample_error_log_filedrop" {
  content = templatefile("${path.module}/templates/sample_error.log.tpl", {
    timestamp = local.static_log_timestamp
    app_name  = "mock-api-service"
    region    = local.region
  })
  filename = "${path.module}/generated_logs/sample_error.log"
}

resource "local_file" "sample_access_log_filedrop" {
  content = templatefile("${path.module}/templates/sample_access.log.tpl", {
    timestamp = local.static_log_timestamp
    app_name  = "mock-api-service"
    region    = local.region
  })
  filename = "${path.module}/generated_logs/sample_access.log"
}

# Upload generated log files to S3
resource "aws_s3_object" "app_log_filedrop" {
  bucket = aws_s3_bucket.mock_log_storage_filedrop.id
  key    = "application-logs/${formatdate("YYYY/MM/DD", timestamp())}/app.log"
  source = local_file.sample_app_log_filedrop.filename
  etag   = local_file.sample_app_log_filedrop.content_md5
  tags   = local.default_tags

  lifecycle {
    ignore_changes = [key, etag] # comment it if you want to update the files
  }
}

resource "aws_s3_object" "error_log_filedrop" {
  bucket = aws_s3_bucket.mock_log_storage_filedrop.id
  key    = "error-logs/${formatdate("YYYY/MM/DD", timestamp())}/error.log"
  source = local_file.sample_error_log_filedrop.filename
  etag   = local_file.sample_error_log_filedrop.content_md5
  tags   = local.default_tags

  lifecycle {
    ignore_changes = [key, etag] # comment it if you want to update the files
  }
}

resource "aws_s3_object" "access_log_filedrop" {
  bucket = aws_s3_bucket.mock_log_storage_filedrop.id
  key    = "access-logs/${formatdate("YYYY/MM/DD", timestamp())}/access.log"
  source = local_file.sample_access_log_filedrop.filename
  etag   = local_file.sample_access_log_filedrop.content_md5
  tags   = local.default_tags

  lifecycle {
    ignore_changes = [key, etag] # comment it if you want to update the files
  }
}
