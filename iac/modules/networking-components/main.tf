module "vpc" {
  source = "./modules/vpc"

  name                     = var.vpc_config.name
  cidr_block               = var.vpc_config.cidr_block
  public_subnet_1_cidr     = var.vpc_config.public_subnet_1_cidr
  public_subnet_1_az       = var.vpc_config.public_subnet_1_az
  public_subnet_2_cidr     = var.vpc_config.public_subnet_2_cidr
  public_subnet_2_az       = var.vpc_config.public_subnet_2_az
  public_subnet_3_cidr     = var.vpc_config.public_subnet_3_cidr
  public_subnet_3_az       = var.vpc_config.public_subnet_3_az
  private_subnet_1_cidr    = var.vpc_config.private_subnet_1_cidr
  private_subnet_1_az      = var.vpc_config.private_subnet_1_az
  private_subnet_2_cidr    = var.vpc_config.private_subnet_2_cidr
  private_subnet_2_az      = var.vpc_config.private_subnet_2_az
  private_subnet_3_cidr    = var.vpc_config.private_subnet_3_cidr
  private_subnet_3_az      = var.vpc_config.private_subnet_3_az
  create_second_nat        = var.vpc_config.create_second_nat
  vpc_enable_dns_hostnames = var.vpc_config.vpc_enable_dns_hostnames
  region                   = var.region
  tags                     = local.combined_tags
}

module "interface_endpoints" {
  source = "./modules/interface_endpoints"

  name = var.interface_endpoints_config.name

  # Service-specific options with consistent grouping
  enable_ssm_session_manager = var.interface_endpoints_config.enable_ssm_session_manager
  enable_sqs                 = var.interface_endpoints_config.enable_sqs
  enable_sns                 = var.interface_endpoints_config.enable_sns
  enable_eventbridge         = var.interface_endpoints_config.enable_eventbridge
  enable_lambda              = var.interface_endpoints_config.enable_lambda
  enable_secrets_manager     = var.interface_endpoints_config.enable_secrets_manager
  enable_iam                 = var.interface_endpoints_config.enable_iam
  enable_cloudwatch          = var.interface_endpoints_config.enable_cloudwatch
  enable_ecr                 = var.interface_endpoints_config.enable_ecr
  enable_ecs                 = var.interface_endpoints_config.enable_ecs
  enable_eks                 = var.interface_endpoints_config.enable_eks

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  region     = var.region
  tags       = local.combined_tags
}
