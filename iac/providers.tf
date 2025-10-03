terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
    observe = {
      source  = "observeinc/observe"
      version = "~>0.13"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~>2.4"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Owner            = var.owner
      CostCenter       = var.cost_center
      Project          = var.project
      Environment      = var.environment
      "user:CreatedBy" = var.created_by
    }
  }
}

provider "observe" {
  customer = var.observe_customer

  api_token = var.observe_token
}
