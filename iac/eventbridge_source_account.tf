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

resource "aws_cloudwatch_event_bus" "source_partner_events" {
  provider = aws.source_account
  name     = "${local.resource_prefix}-source-partner-events"

  tags = {
    Name = "${local.resource_prefix}-source-partner-events"
  }
}

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

