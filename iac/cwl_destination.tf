/*
  CloudWatch Logs Destination (Optional)
  -------------------------------------
  Use these resources ONLY when you need to support cross-account, cross-Region,
  or account-level (organization-wide) log subscriptions. In a simple same-account
  scenario you can point a subscription filter directly at the Firehose delivery
  stream ARN and do NOT need a destination.

  This destination is configured to accept logs from other AWS accounts and
  forward them to the Kinesis Firehose delivery stream, which then sends the
  logs to Observe.
 */


# Destination abstraction (needed for cross-account / advanced scenarios)
resource "aws_cloudwatch_log_destination" "to_firehose" {
  name       = "${local.resource_prefix}-observe-firehose-destination"
  role_arn   = aws_iam_role.to_firehose.arn
  target_arn = module.observe_kinesis_firehose.firehose_delivery_stream.arn
}

resource "aws_iam_role" "to_firehose" {
  name = "${local.resource_prefix}-destination-to-firehose-role"

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
}


resource "aws_iam_role_policy" "to_firehose" {
  name = "${local.resource_prefix}-destination-to-firehose-policy"
  role = aws_iam_role.to_firehose.id
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

# CloudWatch Logs Destination Policy
# This policy determines which AWS accounts/principals can create subscription filters
# to this destination. When cross_account_org_paths is provided, it restricts access
# to specific AWS Organization paths. Otherwise, it allows access from any account
# (which should be further restricted in production).
resource "aws_cloudwatch_log_destination_policy" "to_firehose" {
  destination_name = aws_cloudwatch_log_destination.to_firehose.name
  access_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        AWS = "*"
      },
      Action   = "logs:PutSubscriptionFilter",
      Resource = aws_cloudwatch_log_destination.to_firehose.arn
      # If cross_account_org_paths is provided, restrict access to those org paths
      # Otherwise, allow from any account (should be restricted in production)
      Condition = length(var.cross_account_org_paths) > 0 ? {
        "ForAnyValue:StringLike" : {
          "aws:PrincipalOrgPaths" : var.cross_account_org_paths
        }
      } : null
    }]
  })
}

