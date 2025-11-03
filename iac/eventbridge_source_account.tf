/*
  This file contains EventBridge resources deployed in a SOURCE AWS account.
  These resources simulate a cross-account event bus to event bus communication,
  where events from the source account are forwarded to the destination account.

  Architecture:
  - EventBridge Event Bus (in source account)
  - EventBridge Rule (in source account) with event pattern filter
  - EventBridge Target (in source account) → EventBridge Event Bus (in destination account)

  Note: This simulates AWS Partner events (e.g., Genesys) but uses a "simulate" prefix
  since AWS doesn't allow spoofing partner sources for testing purposes.
 */

# --------------------------------------------------
# Source Account EventBridge Event Bus
# --------------------------------------------------

# Event bus with logging enabled for troubleshooting (not required for production-grade setup)
resource "aws_cloudwatch_event_bus" "source_partner_events" {
  provider = aws.source_account
  name     = "${local.resource_prefix}-source-partner-events"

  log_config {
    level          = "INFO"
    include_detail = "FULL"
  }

  tags = {
    Name = "${local.resource_prefix}-source-partner-events"
  }
}

# EventBridge Archive for troubleshooting (not required for production-grade setup)
resource "aws_cloudwatch_event_archive" "source_partner_events" {
  provider         = aws.source_account
  name             = "${local.resource_prefix}-source-partner-archive"
  event_source_arn = aws_cloudwatch_event_bus.source_partner_events.arn
  retention_days   = 7

  event_pattern = jsonencode({
    source = [{
      prefix = "simulate.aws.partner/genesys.com/"
    }]
  })

  description = "Archive for troubleshooting source partner events - captures events for 7 days replay"
}

# --------------------------------------------------
# CloudWatch Logs for EventBridge (for troubleshooting - not required for production-grade setup)
# --------------------------------------------------

# CloudWatch Log Group to receive EventBridge logs
resource "aws_cloudwatch_log_group" "source_eventbus_logs" {
  provider          = aws.source_account
  name              = "/aws/vendedlogs/events/event-bus/${local.resource_prefix}-source-partner-events"
  retention_in_days = 7

  tags = {
    Name = "${local.resource_prefix}-source-partner-events-logs"
  }
}

# Log delivery source for INFO logs
resource "aws_cloudwatch_log_delivery_source" "source_info_logs" {
  provider     = aws.source_account
  name         = "EventBusSource-${local.resource_prefix}-source-INFO"
  log_type     = "INFO_LOGS"
  resource_arn = aws_cloudwatch_event_bus.source_partner_events.arn
}

# Log delivery source for ERROR logs
resource "aws_cloudwatch_log_delivery_source" "source_error_logs" {
  provider     = aws.source_account
  name         = "EventBusSource-${local.resource_prefix}-source-ERROR"
  log_type     = "ERROR_LOGS"
  resource_arn = aws_cloudwatch_event_bus.source_partner_events.arn
}

# Log delivery destination (CloudWatch Logs)
resource "aws_cloudwatch_log_delivery_destination" "source_cwlogs" {
  provider = aws.source_account
  name     = "EventsDestination-${local.resource_prefix}-source-CWLogs"

  delivery_destination_configuration {
    destination_resource_arn = aws_cloudwatch_log_group.source_eventbus_logs.arn
  }
}

# Resource policy to allow log delivery service to write to log group
resource "aws_cloudwatch_log_resource_policy" "source_eventbus" {
  provider    = aws.source_account
  policy_name = "AWSLogDeliveryWrite-${local.resource_prefix}-source"
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.source_eventbus_logs.arn}:log-stream:*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.source_account.account_id
          }
          ArnLike = {
            "aws:SourceArn" = [
              aws_cloudwatch_log_delivery_source.source_info_logs.arn,
              aws_cloudwatch_log_delivery_source.source_error_logs.arn
            ]
          }
        }
      }
    ]
  })
}

# Link INFO logs to destination
resource "aws_cloudwatch_log_delivery" "source_info_logs" {
  provider                 = aws.source_account
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.source_cwlogs.arn
  delivery_source_name     = aws_cloudwatch_log_delivery_source.source_info_logs.name
}

# Link ERROR logs to destination
resource "aws_cloudwatch_log_delivery" "source_error_logs" {
  provider                 = aws.source_account
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.source_cwlogs.arn
  delivery_source_name     = aws_cloudwatch_log_delivery_source.source_error_logs.name

  depends_on = [aws_cloudwatch_log_delivery.source_info_logs]
}

# --------------------------------------------------
# Source Account EventBridge Rule
# --------------------------------------------------

resource "aws_cloudwatch_event_rule" "source_partner_to_destination" {
  provider       = aws.source_account
  name           = "${local.resource_prefix}-source-partner-forward"
  description    = "Forward partner events from source account to destination account event bus"
  event_bus_name = aws_cloudwatch_event_bus.source_partner_events.name

  # Event pattern to filter AWS Partner events (simulated with "simulate" prefix)
  # Real-world scenario: "aws.partner/genesys.com/*"
  # Testing scenario: "simulate.aws.partner/genesys.com/*"
  event_pattern = jsonencode({
    source = [{
      prefix = "simulate.aws.partner/genesys.com/"
    }]
  })

  tags = {
    Name = "${local.resource_prefix}-source-partner-forward"
  }
}

# IAM role that allows EventBridge in source account to put events to destination event bus
resource "aws_iam_role" "eventbridge_cross_account" {
  provider = aws.source_account
  name     = "${local.resource_prefix}-eventbridge-cross-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.resource_prefix}-eventbridge-cross-account-role"
  }
}

# IAM policy that grants permissions to put events to the destination event bus
resource "aws_iam_role_policy" "eventbridge_cross_account" {
  provider = aws.source_account
  name     = "${local.resource_prefix}-eventbridge-cross-account-policy"
  role     = aws_iam_role.eventbridge_cross_account.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = [
          aws_cloudwatch_event_bus.destination_partner_events.arn
        ]
      }
    ]
  })
}

# --------------------------------------------------
# Source Event Bus Target to Destination Event Bus
# --------------------------------------------------

resource "aws_cloudwatch_event_target" "destination_event_bus" {
  provider       = aws.source_account
  rule           = aws_cloudwatch_event_rule.source_partner_to_destination.name
  event_bus_name = aws_cloudwatch_event_bus.source_partner_events.name
  arn            = aws_cloudwatch_event_bus.destination_partner_events.arn
  role_arn       = aws_iam_role.eventbridge_cross_account.arn

  # Ensure destination event bus, policy, and propagation time are complete
  depends_on = [
    time_sleep.wait_for_eventbus_policy
  ]
}

