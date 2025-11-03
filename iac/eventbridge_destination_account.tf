/*
  This file contains EventBridge resources deployed in the DESTINATION AWS account.
  These resources receive events from the source account's event bus.

  Architecture:
  - EventBridge Event Bus (in destination account)
  - EventBridge Resource Policy (allows source account to put events)
  - EventBridge Rule (in destination account) to process incoming events
  - EventBridge Target (in destination account) → Kinesis Firehose → Observe

  The resource policy enables the source account to send events to this event bus.
 */

# --------------------------------------------------
# Destination Account EventBridge Event Bus
# --------------------------------------------------

resource "aws_cloudwatch_event_bus" "destination_partner_events" {
  name = "${local.resource_prefix}-destination-partner-events"

  tags = {
    Name = "${local.resource_prefix}-destination-partner-events"
  }
}

resource "aws_cloudwatch_event_bus_policy" "allow_source_account" {
  event_bus_name = aws_cloudwatch_event_bus.destination_partner_events.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowSourceAccountPutEvents",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.source_account.account_id}:root"
        },
        Action   = "events:PutEvents",
        Resource = aws_cloudwatch_event_bus.destination_partner_events.arn,
        Condition = {
          StringEquals = {
            "events:source" = ["simulate.aws.partner/genesys.com"]
          }
        }
      }
    ]
  })
}

resource "time_sleep" "wait_for_eventbus_policy" {
  create_duration = "30s"

  depends_on = [
    aws_cloudwatch_event_bus.destination_partner_events,
    aws_cloudwatch_event_bus_policy.allow_source_account
  ]
}

# --------------------------------------------------
# Destination Account EventBridge to Observe Firehose
# --------------------------------------------------

resource "aws_cloudwatch_event_rule" "destination_partner_events" {
  name           = "${local.resource_prefix}-destination-partner-events"
  description    = "Process partner events from source account"
  event_bus_name = aws_cloudwatch_event_bus.destination_partner_events.name

  # Match all events from the simulated partner source
  event_pattern = jsonencode({
    source = [{
      prefix = "simulate.aws.partner/genesys.com/"
    }]
  })

  tags = {
    Name = "${local.resource_prefix}-destination-partner-events"
  }
}

resource "aws_iam_role" "eventbridge_to_firehose" {
  name = "${local.resource_prefix}-eventbridge-to-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "events.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${local.resource_prefix}-eventbridge-to-firehose-role"
  }
}

resource "aws_iam_role_policy" "eventbridge_to_firehose" {
  name = "${local.resource_prefix}-eventbridge-to-firehose-policy"
  role = aws_iam_role.eventbridge_to_firehose.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "firehose:PutRecord",
        "firehose:PutRecordBatch"
      ],
      Resource = module.observe_kinesis_firehose.firehose_delivery_stream.arn
    }]
  })
}

resource "aws_cloudwatch_event_target" "partner_events_to_firehose" {
  rule           = aws_cloudwatch_event_rule.destination_partner_events.name
  event_bus_name = aws_cloudwatch_event_bus.destination_partner_events.name
  arn            = module.observe_kinesis_firehose.firehose_delivery_stream.arn
  role_arn       = aws_iam_role.eventbridge_to_firehose.arn
}
