
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  resource_prefix = "${var.project}-${var.environment}"

  default_tags = {
    Owner            = var.owner
    CostCenter       = var.cost_center
    Project          = var.project
    Environment      = var.environment
    "user:CreatedBy" = var.created_by
  }
}
