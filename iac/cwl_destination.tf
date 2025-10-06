/*
  CloudWatch Logs Destination (Optional)
  -------------------------------------
  Use these resources ONLY when you need to support cross-account, cross-Region,
  or account-level (organization-wide) log subscriptions. In a simple same-account
  scenario you can point a subscription filter directly at the Firehose delivery
  stream ARN and do NOT need a destination.

  Left enabled here for reference; remove or comment out if not required.
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
      Condition : {
        "ForAnyValue:StringLike" : {
          "aws:PrincipalOrgPaths" : ["o-ywdmny0x30/r-hf6b/o-ywdmny0x30/*"]
        }
      }
    }]
  })
}
