# Sample Application Logs
# Generated at: ${timestamp}
# Application: ${app_name}
# Region: ${region}

${timestamp} INFO  [main] Starting ${app_name} application
${timestamp} INFO  [http-nio-8080-exec-1] User authentication successful for user: john.doe@example.com
${timestamp} DEBUG [service-pool-1] Processing order #12345 for customer ID: cust-789
${timestamp} INFO  [service-pool-1] Order #12345 validation completed successfully
${timestamp} INFO  [database-pool-1] Database connection established to primary cluster
${timestamp} WARN  [cache-pool-1] Cache miss for key: user-session-abc123, fallback to database
${timestamp} INFO  [service-pool-2] Payment processing initiated for order #12345, amount: $99.99
${timestamp} INFO  [notification-pool-1] Email notification sent to john.doe@example.com
${timestamp} INFO  [service-pool-2] Payment processed successfully, transaction ID: txn-567890
${timestamp} INFO  [service-pool-1] Order #12345 marked as completed
${timestamp} INFO  [metrics-pool-1] Performance metrics: avg_response_time=125ms, throughput=450req/min
${timestamp} DEBUG [cleanup-pool-1] Cleaned up 15 expired cache entries
${timestamp} INFO  [scheduler-pool-1] Daily backup job scheduled for 02:00 UTC
${timestamp} INFO  [health-check] Application health check passed - all systems operational
${timestamp} INFO  [main] ${app_name} application running smoothly, uptime: 4h 23m 15s
