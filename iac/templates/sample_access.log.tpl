# Sample Access Logs (Common Log Format)
# Generated at: ${timestamp}

192.168.1.10 - - [${timestamp}] "GET /api/v1/users HTTP/1.1" 200 1234 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
10.0.1.25 - john.doe [${timestamp}] "POST /api/v1/orders HTTP/1.1" 201 567 "https://app.example.com/checkout" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
203.0.113.15 - - [${timestamp}] "GET /api/v1/products?category=electronics HTTP/1.1" 200 2048 "-" "curl/7.68.0"
192.168.1.42 - jane.smith [${timestamp}] "PUT /api/v1/profile HTTP/1.1" 200 123 "https://app.example.com/profile" "Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15"
10.0.2.8 - - [${timestamp}] "GET /health HTTP/1.1" 200 15 "-" "ELB-HealthChecker/2.0"
192.168.1.67 - admin [${timestamp}] "DELETE /api/v1/users/12345 HTTP/1.1" 204 0 "https://admin.example.com/users" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
203.0.113.99 - - [${timestamp}] "GET /api/v1/orders/67890 HTTP/1.1" 404 78 "-" "PostmanRuntime/7.28.4"
10.0.1.33 - service.account [${timestamp}] "POST /api/v1/webhooks/payment HTTP/1.1" 200 245 "-" "PaymentGateway-Webhook/1.0"
192.168.1.88 - - [${timestamp}] "GET /static/js/app.bundle.js HTTP/1.1" 200 156789 "https://app.example.com/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
10.0.2.15 - analytics [${timestamp}] "POST /api/v1/events HTTP/1.1" 202 45 "https://app.example.com/dashboard" "AnalyticsTracker/2.1.0"
203.0.113.200 - - [${timestamp}] "GET /api/v1/search?q=laptop HTTP/1.1" 200 3456 "https://app.example.com/search" "Mozilla/5.0 (Android 11; Mobile; rv:68.0) Gecko/68.0 Firefox/88.0"
192.168.1.123 - guest [${timestamp}] "GET /api/v1/public/status HTTP/1.1" 200 89 "-" "StatusMonitor/1.0"
