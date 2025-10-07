locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  resource_prefix = "${var.project}-${var.environment}"

  # Static timestamp used in generated local_file resources to avoid perpetual diffs
  static_log_timestamp = "2025-10-08 11:00:00"

  default_tags = {
    Owner            = var.owner
    CostCenter       = var.cost_center
    Project          = var.project
    Environment      = var.environment
    "user:CreatedBy" = var.created_by
  }
}
