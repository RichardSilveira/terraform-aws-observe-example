/*
  This file configures forwarding of AWS Lambda metrics to Observe via CloudWatch Metric Streams.

  Flow:
    AWS/Lambda Metrics -> CloudWatch Metric Stream (JSON) -> Kinesis Firehose -> Observe

  Notes:
    - Reuses the existing Observe Kinesis Firehose (module.observe_kinesis_firehose)
    - Only streams AWS/Lambda namespace metrics to control costs
    - Metrics include: Invocations, Errors, Duration, Throttles, ConcurrentExecutions, etc.
    - Format is JSON (OpenTelemetry 1.0.0 compatible)

  Important:
    - This is for same-account forwarding of Lambda metrics to Observe.
    - If you need cross-account forwarding, a way more complex additional setup is required
      as CloudWatch Metric Streams do not support cross-account destinations natively
      (it can NOT target a CWL Destination like CWL can - only Firehose directly in the same account).

 */

# --------------------------------------------------
# IAM Role for CloudWatch Metric Stream
# --------------------------------------------------
resource "aws_iam_role" "metric_stream_to_firehose" {
  name = "${local.resource_prefix}-metric-stream-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "streams.metrics.cloudwatch.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.resource_prefix}-metric-stream-firehose-role"
  }
}

resource "aws_iam_role_policy" "metric_stream_to_firehose" {
  name = "${local.resource_prefix}-metric-stream-firehose-policy"
  role = aws_iam_role.metric_stream_to_firehose.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        Resource = module.observe_kinesis_firehose.firehose_delivery_stream.arn
      }
    ]
  })
}

# --------------------------------------------------
# CloudWatch Log Group for Metric Stream
# --------------------------------------------------
resource "aws_cloudwatch_log_group" "metric_stream" {
  name              = "/aws/cloudwatch/metric-stream/${local.resource_prefix}-lambda-metrics"
  retention_in_days = 7

  tags = {
    Name = "${local.resource_prefix}-metric-stream-logs"
  }
}

# --------------------------------------------------
# CloudWatch Metric Stream - AWS/Lambda Metrics
# --------------------------------------------------
resource "aws_cloudwatch_metric_stream" "lambda_metrics" {
  name          = "${local.resource_prefix}-lambda-metrics-stream"
  role_arn      = aws_iam_role.metric_stream_to_firehose.arn
  firehose_arn  = module.observe_kinesis_firehose.firehose_delivery_stream.arn
  output_format = "json"

  # Only include AWS/Lambda namespace metrics to control costs and volume
  include_filter {
    namespace    = "AWS/Lambda"
    metric_names = []
  }

  tags = {
    Name = "${local.resource_prefix}-lambda-metrics-stream"
  }
}
