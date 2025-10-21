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
      but this approach lacks flexibility in comparison to using EventBridge rules.
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
      "object" : { "key" : [{ "prefix" : "observe/" }] }
    }
  })
}

resource "aws_cloudwatch_event_target" "to_observe_lambda" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "${local.resource_prefix}-observe-lambda"
  arn       = module.observe_s3_forwarder_lambda.lambda_function.arn

  dead_letter_config {
    arn = aws_sqs_queue.eventbridge_dlq.arn
  }

  # Transform EventBridge S3 event -> classic S3 notification shape
  input_transformer {
    input_paths = {
      bucket    = "$.detail.bucket.name"
      key       = "$.detail.object.key"
      size      = "$.detail.object.size"
      etag      = "$.detail.object.etag"
      sequencer = "$.detail.object.sequencer"
      region    = "$.region"
      time      = "$.time"
    }

    # Minimal S3 notification envelope
    input_template = <<EOT
{
  "Records": [
    {
      "eventVersion": "2.1",
      "eventSource": "aws:s3",
      "awsRegion": "<region>",
      "eventTime": "<time>",
      "eventName": "ObjectCreated:Put",
      "s3": {
        "s3SchemaVersion": "1.0",
        "bucket": {
          "name": "<bucket>",
          "arn": "arn:aws:s3:::<bucket>"
        },
        "object": {
          "key": "<key>",
          "size": <size>,
          "eTag": "<etag>",
          "sequencer": "<sequencer>"
        }
      }
    }
  ]
}
EOT
  }
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.observe_s3_forwarder_lambda.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_object_created.arn
}

data "aws_iam_policy_document" "s3_read" {

  # (note from observe): `s3:ListBucket` is not strictly required, but it allows us to receive a 404
  # instead of 403 error if an S3 object no longer exists by the time our
  # lambda function tries to retrieve it
  statement {
    sid       = "ListBuckets"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.mock_log_storage.arn]
  }

  statement {
    sid       = "GetObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.mock_log_storage.arn}/*"]
  }
}

resource "aws_iam_policy" "s3_bucket_read" {
  name   = "${local.resource_prefix}-s3-bucket-read"
  policy = data.aws_iam_policy_document.s3_read.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3_bucket_read" {
  role       = element(split("/", module.observe_s3_forwarder_lambda.lambda_function.role), 1)
  policy_arn = aws_iam_policy.s3_bucket_read.arn
}

# --------------------------------------------------
# Dead Letter Queue for EventBridge Target
# --------------------------------------------------
resource "aws_sqs_queue" "eventbridge_dlq" {
  name                      = "${local.resource_prefix}-eventbridge-dlq"
  sqs_managed_sse_enabled   = true
  message_retention_seconds = 604800 # 7 days
}

data "aws_iam_policy_document" "eventbridge_dlq_policy" {
  statement {
    sid    = "AllowEventBridgeToSendMessages"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "sqs:SendMessage"
    ]

    resources = [aws_sqs_queue.eventbridge_dlq.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "eventbridge_dlq_policy" {
  queue_url = aws_sqs_queue.eventbridge_dlq.id
  policy    = data.aws_iam_policy_document.eventbridge_dlq_policy.json
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

