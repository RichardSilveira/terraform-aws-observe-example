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
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
    local = {
      source  = "hashicorp/local"
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

# Source account provider for cross-account CloudWatch Logs subscription
provider "aws" {
  region  = var.source_account_region
  profile = var.source_account_profile
  alias   = "source_account"

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

# provider "aws" {
#   region  = "us-west-2"
#   alias   = "us_west_2" # Needed for Observe Filedrop free tier accounts
#   profile = var.aws_profile

#   default_tags {
#     tags = {
#       Owner            = var.owner
#       CostCenter       = var.cost_center
#       Project          = var.project
#       Environment      = var.environment
#       "user:CreatedBy" = var.created_by
#     }
#   }
# }

provider "observe" {
  customer = var.observe_customer

  api_token = var.observe_token
}
