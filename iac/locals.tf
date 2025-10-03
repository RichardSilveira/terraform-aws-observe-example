
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  resource_prefix = "${var.project}-${var.environment}"

  # CloudWatch log retention configuration
  cloudwatch_log_retention_days = var.cloudwatch_log_retention_days != null ? var.cloudwatch_log_retention_days : 7

  default_tags = {
    Owner            = var.owner
    CostCenter       = var.cost_center
    Project          = var.project
    Environment      = var.environment
    "user:CreatedBy" = var.created_by
  }
}
