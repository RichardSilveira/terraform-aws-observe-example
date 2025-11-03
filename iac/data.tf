data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --------------------------------------------------
# Source Account Data Sources
# --------------------------------------------------
data "aws_caller_identity" "source_account" {
  provider = aws.source_account
}

data "aws_region" "source_account" {
  provider = aws.source_account
}
