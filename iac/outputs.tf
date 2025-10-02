# --------------------------------------------------
# VPC outputs
# --------------------------------------------------
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "The IDs of the NAT Gateways"
  value       = module.networking.nat_gateway_ids
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = module.networking.internet_gateway_id
}

# --------------------------------------------------
# Interface Endpoints outputs
# --------------------------------------------------
output "interface_vpc_endpoint_ids" {
  description = "List of interface VPC endpoint IDs for security group associations"
  value       = module.networking.interface_vpc_endpoint_ids
}

output "interface_endpoints_security_group_id" {
  description = "Security group ID for interface VPC endpoints"
  value       = module.networking.interface_endpoints_security_group_id
}

output "interface_endpoint_dns_names" {
  description = "Map of interface endpoint DNS names by service"
  value       = module.networking.interface_endpoint_dns_names
}

output "interface_endpoint_details" {
  description = "Detailed information about all interface endpoints"
  value       = module.networking.interface_endpoint_details
}

output "enabled_interface_endpoint_services" {
  description = "List of enabled interface endpoint services"
  value       = module.networking.enabled_interface_endpoint_services
}
