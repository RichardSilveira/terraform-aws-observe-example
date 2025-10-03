# todo - rename this file to `observe_cwl_forwarder.tf`
# --------------------------------------------------
# Observe CloudWatch Logs Forwarder
# --------------------------------------------------
# This file contains resources for forwarding CloudWatch Logs to the Observe platform
# via Kinesis Firehose for centralized logging and observability
# todo - format the comment from above that explains the file purpose as I did for the `mock_resources.tf` file

# --------------------------------------------------
# S3 Bucket for Firehose failed events
# --------------------------------------------------
resource "aws_s3_bucket" "observe_firehose_failed_events" {
  bucket = "${local.resource_prefix}-observe-firehose-failed-events"

  tags = local.default_tags
}

resource "aws_s3_bucket_versioning" "observe_firehose_failed_events" {
  bucket = aws_s3_bucket.observe_firehose_failed_events.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "observe_firehose_failed_events" {
  bucket = aws_s3_bucket.observe_firehose_failed_events.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------------------------------
# CloudWatch Log Group for Firehose logging
# --------------------------------------------------
resource "aws_cloudwatch_log_group" "firehose_cwl" {
  name              = format("/aws/firehose/%s", "${local.resource_prefix}-observe-firehose-cwl")
  retention_in_days = local.cloudwatch_log_retention_days # todo - remove this local variable. Do not inform `retention_in_days` in favor of simplicity

  tags = local.default_tags
}

# --------------------------------------------------
# Observe Kinesis Firehose Delivery Stream
# --------------------------------------------------
module "observe_kinesis_firehose" {
  source  = "observeinc/kinesis-firehose/aws"
  version = "2.4.1"

  name                        = "${local.resource_prefix}-observe-firehose"
  observe_collection_endpoint = var.observe_collection_endpoint
  observe_token               = var.observe_token

  iam_name_prefix = local.resource_prefix
  s3_delivery_bucket = {
    arn = aws_s3_bucket.observe_firehose_failed_events.arn
  }

  http_endpoint_buffering_interval = 60 # buffering data in secs before sending to Observe via http
  cloudwatch_log_group             = aws_cloudwatch_log_group.firehose_cwl

  tags = local.default_tags
}

# todo - I think we can remove Cloudwatch Log Destination for now as we are in the same account and do not need cross-account forwarding
# --------------------------------------------------
# CloudWatch Logs Destination for same-account forwarding
# --------------------------------------------------
# IAM Role (and its policies) that CWL assumes to write to Firehose
resource "aws_iam_role" "cwl_to_firehose" {
  name = "${local.resource_prefix}-cwl-to-firehose-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "logs.${local.region}.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.default_tags
}

resource "aws_iam_role_policy" "cwl_to_firehose" {
  role = aws_iam_role.cwl_to_firehose.id
  name = "${local.resource_prefix}-cwl-to-firehose-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["firehose:PutRecord", "firehose:PutRecordBatch"],
      Resource = module.observe_kinesis_firehose.firehose_delivery_stream.arn
    }]
  })
}

# CWL destination pointing at the Firehose
resource "aws_cloudwatch_log_destination" "to_firehose" {
  name       = "${local.resource_prefix}-observe-firehose-destination"
  role_arn   = aws_iam_role.cwl_to_firehose.arn
  target_arn = module.observe_kinesis_firehose.firehose_delivery_stream.arn

  tags = local.default_tags
}

# CWL Destination Resource Policy to allow same-account access to attach subscription filters
resource "aws_cloudwatch_log_destination_policy" "to_firehose" {
  destination_name = aws_cloudwatch_log_destination.to_firehose.name
  access_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        AWS = "arn:aws:iam::${local.account_id}:root"
      },
      Action   = "logs:PutSubscriptionFilter",
      Resource = aws_cloudwatch_log_destination.to_firehose.arn
    }]
  })
}
