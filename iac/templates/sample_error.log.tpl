# Sample Error Logs
# Generated at: ${timestamp}
# Application: ${app_name}
# Region: ${region}

${timestamp} ERROR [http-nio-8080-exec-3] Authentication failed for user: hacker@malicious.com - Invalid credentials
${timestamp} WARN  [service-pool-1] Rate limit exceeded for IP: 192.168.1.100, requests blocked
${timestamp} ERROR [database-pool-1] Connection timeout to database cluster after 30s
${timestamp} WARN  [database-pool-1] Retrying database connection (attempt 2/3)
${timestamp} INFO  [database-pool-1] Database connection restored successfully
${timestamp} ERROR [payment-service] Payment gateway timeout for transaction: txn-error-123
${timestamp} WARN  [payment-service] Initiating payment retry mechanism
${timestamp} ERROR [service-pool-2] Validation error: Invalid email format for user registration
${timestamp} WARN  [cache-pool-1] Redis connection unstable, switching to backup cache
${timestamp} ERROR [external-api] Third-party service unavailable: HTTP 503 from partner-api.example.com
${timestamp} WARN  [circuit-breaker] Circuit breaker opened for external-api service
${timestamp} ERROR [file-processor] Failed to process uploaded file: corrupted_data.csv - Invalid format
${timestamp} WARN  [monitoring] High memory usage detected: 85% of available heap
${timestamp} ERROR [security] Potential SQL injection attempt detected from IP: 203.0.113.5
${timestamp} WARN  [security] Blocked suspicious request pattern from user: suspicious@domain.com
