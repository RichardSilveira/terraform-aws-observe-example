/*
  This file contains resources for forwarding CloudWatch Logs to the Observe platform
  via Kinesis Firehose
 */

# --------------------------------------------------
# S3 Bucket for Firehose failed events
# --------------------------------------------------
resource "aws_s3_bucket" "observe_firehose_failed_events" {
  bucket = "${local.resource_prefix}-observe-firehose-failed-events"

  # tags = local.default_tags
}

resource "aws_s3_bucket_public_access_block" "observe_firehose_failed_events" {
  bucket = aws_s3_bucket.observe_firehose_failed_events.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------------------------------
# Observe Kinesis Firehose
# --------------------------------------------------
module "observe_kinesis_firehose" {
  source  = "observeinc/kinesis-firehose/aws"
  version = "2.4.1"

  name                        = "${local.resource_prefix}-observe-firehose"
  observe_collection_endpoint = var.observe_collection_endpoint
  observe_customer            = var.observe_customer
  observe_token               = var.observe_token

  iam_name_prefix = local.resource_prefix
  s3_delivery_bucket = {
    arn = aws_s3_bucket.observe_firehose_failed_events.arn
  }

  http_endpoint_buffering_interval = 60
  cloudwatch_log_group             = aws_cloudwatch_log_group.firehose_cwl

  # tags = local.default_tags
}

resource "aws_cloudwatch_log_group" "firehose_cwl" {
  name = format("/aws/firehose/%s", "${local.resource_prefix}-observe-firehose-cwl")

  tags = local.default_tags
}

# This role allows CloudWatch Logs to put log events to the Firehose delivery stream
resource "aws_iam_role" "cwl_direct_to_firehose" {
  name = "${local.resource_prefix}-cwl-direct-to-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "logs.${local.region}.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })

  # tags = local.default_tags
}

resource "aws_iam_role_policy" "cwl_direct_to_firehose" {
  name = "${local.resource_prefix}-cwl-direct-to-firehose-policy"
  role = aws_iam_role.cwl_direct_to_firehose.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["firehose:PutRecord", "firehose:PutRecordBatch"],
        Resource = module.observe_kinesis_firehose.firehose_delivery_stream.arn
      }
    ]
  })
}
