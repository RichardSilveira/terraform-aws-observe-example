/*
  This file configures forwarding of S3 object-created events to Observe.

  Flow:
    S3 Bucket (objects/log files) -> Event notification -> Observe Lambda forwarder -> Observe ingest endpoint

  Notes:
    - We reuse the example/mock log bucket defined in `mock_resources.tf`.
    - The Observe community module deploys a purpose-built Lambda that batches & ships data.
    - For a real deployment, list all production bucket ARNs you want to forward.
    - VPC networking is intentionally omitted here to keep the example minimal. Uncomment or extend
      with vpc_config if you need the Lambda inside a VPC.
 */

# --------------------------------------------------
# Observe Lambda Forwarder (S3 Events)
# --------------------------------------------------
module "observe_s3_forwarder_lambda" {
  source  = "observeinc/lambda/aws"
  version = "3.6.0"

  name             = "${local.resource_prefix}-s3-forwarder"
  observe_customer = var.observe_customer
  observe_token    = var.observe_token
  iam_name_prefix  = local.resource_prefix

  # Run inside VPC private subnets for egress through NAT Gateway (networking module provides these)
  vpc_config = {
    subnets = [for id in module.networking.private_subnet_ids : { id : id, arn : "arn:aws:ec2:${local.region}:${local.account_id}:subnet/${id}" }]
    security_groups = [
      { id = aws_security_group.observe_s3_forwarder_lambda.id }
    ]
  }
}

# --------------------------------------------------
# S3 Bucket Subscriptions
# --------------------------------------------------
# Attach the forwarder Lambda to one or more S3 buckets. For the example we use
# the mock log storage bucket that is populated with sample log files.

/* 🧙‍♂️ Observe recommends subscribe the Lambda directly in the S3 for the sake of simplicity,
    but you can also use EventBridge rules, which is better for cross-account scenarios, plus,
    in case you already have any event notification configured in the bucket, to avoid conflicts.
*/
# module "observe_s3_bucket_subscription" {
#   source  = "observeinc/lambda/aws//modules/s3_bucket_subscription"
#   version = "3.6.0"

#   lambda          = module.observe_s3_forwarder_lambda.lambda_function
#   bucket_arns     = [aws_s3_bucket.mock_log_storage.arn]
#   iam_name_prefix = local.resource_prefix
# }

resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name        = "${local.resource_prefix}-s3-object-created-to-observe"
  description = "Route S3 Object Created events to the Observe lambda"
  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["Object Created"],
    "detail" : {
      "bucket" : { "name" : ["${aws_s3_bucket.mock_log_storage.bucket}"] },
    }
  })
}

resource "aws_cloudwatch_event_target" "to_observe_lambda" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "${local.resource_prefix}-observe-lambda"
  arn       = module.observe_s3_forwarder_lambda.lambda_function.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.observe_s3_forwarder_lambda.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_object_created.arn
}

# --------------------------------------------------
# Security Group for Lambda
# --------------------------------------------------
resource "aws_security_group" "observe_s3_forwarder_lambda" {
  name        = "${local.resource_prefix}-observe-s3-forwarder-lambda-sg"
  description = "Security group for Observe S3 forwarder Lambda"
  vpc_id      = module.networking.vpc_id

  # Egress only SG (Lambda needs outbound HTTPS to Observe ingest)
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }
}

