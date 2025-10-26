output "id" {
  description = "Virtual Network resource ID"
  value       = azurerm_virtual_network.main.id
}

output "name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.main.name
}

output "address_space" {
  description = "Virtual Network address space"
  value       = azurerm_virtual_network.main.address_space
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to address prefixes"
  value       = { for k, v in azurerm_subnet.subnets : k => v.address_prefixes }
}

output "network_security_group_ids" {
  description = "Map of NSG names to IDs"
  value       = { for k, v in azurerm_network_security_group.nsgs : k => v.id }
}

output "route_table_ids" {
  description = "Map of Route Table names to IDs"
  value       = { for k, v in azurerm_route_table.route_tables : k => v.id }
}

output "vnet_guid" {
  description = "Virtual Network GUID"
  value       = azurerm_virtual_network.main.guid
}