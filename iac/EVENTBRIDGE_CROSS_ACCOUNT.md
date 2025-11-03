# Cross-Account EventBridge: Event Bus to Event Bus Communication

This directory contains Terraform configurations for setting up cross-account EventBridge event bus communication, simulating AWS Partner events (e.g., Genesys) being forwarded from a source account to a destination account.

## Overview

This use case demonstrates how to forward events from an EventBridge event bus in one AWS account (source) to an EventBridge event bus in another AWS account (destination). This pattern is commonly used when:

- Centralizing partner events from multiple accounts
- Implementing multi-account event-driven architectures
- Processing AWS Partner events (like Genesys, Salesforce, etc.) in a central account

## Architecture

```
┌─────────────────────────────────────────┐
│         Source Account                   │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ EventBridge Event Bus              │ │
│  │ (source-partner-events)            │ │
│  └──────────────┬─────────────────────┘ │
│                 │                        │
│  ┌──────────────▼─────────────────────┐ │
│  │ EventBridge Rule                   │ │
│  │ (Filter: simulate.aws.partner/    │ │
│  │          genesys.com/*)            │ │
│  └──────────────┬─────────────────────┘ │
│                 │                        │
│  ┌──────────────▼─────────────────────┐ │
│  │ EventBridge Target                 │ │
│  │ (Destination Event Bus ARN)        │ │
│  └────────────────────────────────────┘ │
│                 │                        │
└─────────────────┼────────────────────────┘
                  │ Cross-Account
                  │ PutEvents
                  ▼
┌─────────────────────────────────────────┐
│      Destination Account (Default)       │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ EventBridge Event Bus              │ │
│  │ (destination-partner-events)       │ │
│  │                                     │ │
│  │ Resource Policy:                   │ │
│  │ - Principal: Source Account        │ │
│  │ - Action: events:PutEvents         │ │
│  │ - Condition: events:source         │ │
│  └──────────────┬─────────────────────┘ │
│                 │                        │
│  ┌──────────────▼─────────────────────┐ │
│  │ EventBridge Rule                   │ │
│  │ (Process incoming partner events)  │ │
│  └──────────────┬─────────────────────┘ │
│                 │                        │
│  ┌──────────────▼─────────────────────┐ │
│  │ Kinesis Firehose                   │ │
│  │ (observe-firehose)                 │ │
│  │                                     │ │
│  │ → Forwards directly to Observe     │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## Key Components

### Source Account Resources (`eventbridge_source_account.tf`)

1. **Event Bus** - Custom event bus to receive partner events
2. **EventBridge Rule** - Filters events with source pattern `simulate.aws.partner/genesys.com/*`
3. **IAM Role** - Allows EventBridge to put events to the destination event bus (required for cross-account targets created after March 2, 2023)
4. **EventBridge Target** - Points to the destination account's event bus

### Destination Account Resources (`eventbridge_destination_account.tf`)

1. **Event Bus** - Custom event bus to receive events from source account
2. **Resource Policy** - Allows source account to put events
   - Principal: Source AWS Account root
   - Action: `events:PutEvents`
   - Condition: Validates event source
3. **EventBridge Rule** - Processes incoming partner events
4. **IAM Role** - Allows EventBridge to write to Kinesis Firehose
5. **EventBridge Target** - Points to Kinesis Firehose delivery stream
6. **Kinesis Firehose** - Delivers events directly to Observe (reuses existing `observe_kinesis_firehose`)

## Event Pattern

The configuration uses a simulated AWS Partner source:

```json
{
  "source": [{
    "prefix": "simulate.aws.partner/genesys.com/"
  }]
}
```

### Why "simulate" prefix?

AWS does not allow spoofing partner event sources for testing purposes. In production, real partner events would use:
- `aws.partner/genesys.com/*`

For testing, we use:
- `simulate.aws.partner/genesys.com/*`

## Security Model

This implementation uses **both resource-based policies and IAM roles**:

1. **Source Account IAM Role**: Required for cross-account event bus targets (AWS requirement since March 2, 2023)
   - Allows EventBridge service to assume the role
   - Grants `events:PutEvents` permission to destination event bus

2. **Destination Event Bus Resource Policy**: Controls which accounts can send events
   - Principal: Source AWS Account root
   - Action: `events:PutEvents`
   - Condition: Validates the event source matches expected partner pattern

3. **Destination EventBridge to Firehose IAM Role**: Allows EventBridge to write to Kinesis Firehose

### Important Note

AWS now requires IAM roles for all new cross-account event bus targets created after March 2, 2023. This ensures organization boundaries using Service Control Policies (SCPs) can be properly applied to control who can send and receive events across accounts.

## Integration with Observe

The partner events are forwarded **directly to Kinesis Firehose** in the destination account, which then delivers them to the Observe platform via HTTP endpoint. This provides:

1. **Lower latency** - Direct delivery without intermediate CloudWatch Logs
2. **Cost efficiency** - Eliminates CloudWatch Logs storage costs
3. **Simplified architecture** - Fewer components in the data path
4. **Automatic batching** - Firehose handles buffering and batching
5. **Built-in retry logic** - Firehose provides automatic retries and error handling

The configuration reuses the existing `observe_kinesis_firehose` module already deployed for CloudWatch Logs forwarding.

## Files

- `eventbridge_source_account.tf` - Source account EventBridge resources
- `eventbridge_destination_account.tf` - Destination account EventBridge resources and policies
- `outputs.tf` - Outputs for event bus ARNs, names, and log groups

## Cost Considerations

- **EventBridge Custom Event Bus**: No charge for custom event buses
- **EventBridge Events**: $1.00 per million custom events
- **Cross-Account Event Delivery**: No additional charge (same region)
- **Kinesis Firehose**: $0.029 per GB ingested (first 500 TB/month)
- **Data Transfer**: No charge for same-region event delivery
- **S3 Backup**: Standard S3 pricing for failed events (minimal with proper configuration)

## Real-World Use Cases

1. **Genesys Cloud Events**: Contact center events, conversation analytics
2. **Salesforce Events**: CRM updates, opportunity changes
3. **Auth0 Events**: Authentication and authorization events
4. **DataDog Events**: Monitoring and alerting events
5. **New Relic Events**: Application performance events

## References

- [AWS EventBridge Cross-Account Event Delivery](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-cross-account.html)
- [EventBridge Partner Event Sources](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-saas.html)
- [Genesys Cloud Integration](https://help.mypurecloud.com/articles/about-the-amazon-eventbridge-integration/)
