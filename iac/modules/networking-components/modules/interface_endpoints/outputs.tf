output "interface_vpc_endpoint_ids" {
  description = "List of interface VPC endpoint IDs for security group associations"
  value = length(local.enabled_endpoints) > 0 ? [
    for endpoint in aws_vpc_endpoint.interface_endpoints : endpoint.id
  ] : []
}

output "interface_endpoints_security_group_id" {
  description = "Security group ID for interface VPC endpoints"
  value       = length(local.enabled_endpoints) > 0 ? aws_security_group.interface_endpoints_sg[0].id : null
}

output "interface_endpoint_dns_names" {
  description = "Map of interface endpoint DNS names by service"
  value = length(local.enabled_endpoints) > 0 ? {
    for service_key, endpoint in aws_vpc_endpoint.interface_endpoints : service_key => endpoint.dns_entry[0]["dns_name"]
  } : {}
}

output "interface_endpoint_details" {
  description = "Detailed information about all interface endpoints"
  value = length(local.enabled_endpoints) > 0 ? {
    for service_key, endpoint in aws_vpc_endpoint.interface_endpoints : service_key => {
      id                    = endpoint.id
      service_name          = endpoint.service_name
      dns_name              = endpoint.dns_entry[0]["dns_name"]
      subnet_ids            = endpoint.subnet_ids
      network_interface_ids = endpoint.network_interface_ids
    }
  } : {}
}

output "enabled_services" {
  description = "List of enabled interface endpoint services"
  value       = keys(local.enabled_endpoints)
}
