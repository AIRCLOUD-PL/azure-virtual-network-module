/**
 * # Azure Virtual Network Module
 *
 * Enterprise-grade Azure Virtual Network module with comprehensive networking features.
 *
 * ## Features
 * - Virtual Network with multiple address spaces
 * - Subnets with delegation and service endpoints
 * - Network Security Groups with rules
 * - Route Tables with custom routes
 * - DDoS Protection Standard
 * - Network Watcher integration
 * - Azure Policy integration
 * - DNS configuration
 */

locals {
  # Auto-generate VNet name if not provided
  vnet_name = var.name != null ? var.name : "${var.naming_prefix}${var.environment}${replace(var.location, "-", "")}vnet"

  # Default tags
  default_tags = {
    ManagedBy   = "Terraform"
    Module      = "azure-virtual-network"
    Environment = var.environment
  }

  tags = merge(local.default_tags, var.tags)
}

# Resource Group (if not provided externally)
resource "azurerm_resource_group" "main" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space

  # DNS servers
  dns_servers = var.dns_servers

  # DDoS Protection
  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection ? [1] : []
    content {
      id     = var.ddos_protection_plan_id != null ? var.ddos_protection_plan_id : azurerm_network_ddos_protection_plan.main[0].id
      enable = true
    }
  }

  # Encryption
  dynamic "encryption" {
    for_each = var.encryption_enforcement != null ? [1] : []
    content {
      enforcement = var.encryption_enforcement
    }
  }

  tags = local.tags

  depends_on = [
    azurerm_resource_group.main,
    azurerm_network_ddos_protection_plan.main
  ]
}

# DDoS Protection Plan
resource "azurerm_network_ddos_protection_plan" "main" {
  count               = var.enable_ddos_protection && var.ddos_protection_plan_id == null ? 1 : 0
  name                = "${local.vnet_name}-ddos"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags

  depends_on = [
    azurerm_resource_group.main
  ]
}

# NAT Gateways
resource "azurerm_nat_gateway" "nat_gateways" {
  for_each = var.nat_gateways

  name                    = each.key
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = try(each.value.sku_name, "Standard")
  idle_timeout_in_minutes = try(each.value.idle_timeout_in_minutes, 4)
  zones                   = try(each.value.zones, [])

  tags = local.tags

  depends_on = [
    azurerm_resource_group.main
  ]
}

# NAT Gateway Public IPs
resource "azurerm_public_ip" "nat_pips" {
  for_each = {
    for nat_key, nat in var.nat_gateways : nat_key => nat
    if try(nat.public_ip, null) != null
  }

  name                = "${each.key}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = try(each.value.public_ip.allocation_method, "Static")
  sku                 = try(each.value.public_ip.sku, "Standard")
  zones               = try(each.value.public_ip.zones, [])

  tags = local.tags

  depends_on = [
    azurerm_resource_group.main
  ]
}

# NAT Gateway Public IP Associations
resource "azurerm_nat_gateway_public_ip_association" "nat_pip_associations" {
  for_each = {
    for nat_key, nat in var.nat_gateways : nat_key => nat
    if try(nat.public_ip, null) != null
  }

  nat_gateway_id       = azurerm_nat_gateway.nat_gateways[each.key].id
  public_ip_address_id = azurerm_public_ip.nat_pips[each.key].id
}

# Network Watcher
resource "azurerm_network_watcher" "main" {
  count = var.enable_network_watcher ? 1 : 0

  name                = "${local.vnet_name}-watcher"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags

  depends_on = [
    azurerm_resource_group.main
  ]
}

# Flow Logs (requires Network Watcher)
resource "azurerm_network_watcher_flow_log" "flow_logs" {
  for_each = {
    for subnet_key, subnet in var.subnets : subnet_key => subnet
    if try(subnet.enable_flow_logs, false) && var.enable_network_watcher
  }

  network_watcher_name = azurerm_network_watcher.main[0].name
  resource_group_name  = var.resource_group_name
  name                 = "${each.key}-flow-log"

  network_security_group_id = try(azurerm_network_security_group.nsgs[try(each.value.network_security_group_keys[0], "")].id, null)
  storage_account_id        = var.flow_logs_storage_account_id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = try(each.value.flow_logs_retention_days, 30)
  }

  dynamic "traffic_analytics" {
    for_each = try(each.value.enable_traffic_analytics, false) ? [1] : []
    content {
      enabled               = true
      workspace_id          = var.log_analytics_workspace_id
      workspace_region      = var.location
      workspace_resource_id = var.log_analytics_workspace_resource_id
      interval_in_minutes   = try(each.value.traffic_analytics_interval, 60)
    }
  }

  depends_on = [
    azurerm_network_watcher.main,
    azurerm_network_security_group.nsgs
  ]
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "vnet_diagnostics" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "${local.vnet_name}-diagnostics"
  target_resource_id         = azurerm_virtual_network.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.diagnostic_settings.logs
    content {
      category = enabled_log.value.category
    }
  }

  dynamic "metric" {
    for_each = var.diagnostic_settings.metrics
    content {
      category = metric.value.category
      enabled  = metric.value.enabled
    }
  }
}

# Subnets
resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes

  # Service endpoints
  service_endpoints = try(each.value.service_endpoints, [])

  # Delegation
  dynamic "delegation" {
    for_each = try(each.value.delegations, [])
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = try(delegation.value.actions, [])
      }
    }
  }

  # Private endpoint network policies
  private_endpoint_network_policies = try(each.value.private_endpoint_network_policies_enabled, true) ? "Enabled" : "Disabled"

  # Private link service network policies  
  private_link_service_network_policies_enabled = try(each.value.private_link_service_network_policies_enabled, true)
}

# Network Security Groups
resource "azurerm_network_security_group" "nsgs" {
  for_each = var.network_security_groups

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = try(each.value.security_rules, [])
    content {
      name                                       = security_rule.value.name
      priority                                   = security_rule.value.priority
      direction                                  = security_rule.value.direction
      access                                     = security_rule.value.access
      protocol                                   = security_rule.value.protocol
      source_port_range                          = try(security_rule.value.source_port_range, null)
      source_port_ranges                         = try(security_rule.value.source_port_ranges, null)
      destination_port_range                     = try(security_rule.value.destination_port_range, null)
      destination_port_ranges                    = try(security_rule.value.destination_port_ranges, null)
      source_address_prefix                      = try(security_rule.value.source_address_prefix, null)
      source_address_prefixes                    = try(security_rule.value.source_address_prefixes, null)
      destination_address_prefix                 = try(security_rule.value.destination_address_prefix, null)
      destination_address_prefixes               = try(security_rule.value.destination_address_prefixes, null)
      source_application_security_group_ids      = try(security_rule.value.source_application_security_group_ids, null)
      destination_application_security_group_ids = try(security_rule.value.destination_application_security_group_ids, null)
    }
  }

  tags = local.tags
}

# Route Tables
resource "azurerm_route_table" "route_tables" {
  for_each = var.route_tables

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "route" {
    for_each = try(each.value.routes, [])
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = try(route.value.next_hop_in_ip_address, null)
    }
  }

  # BGP route propagation
  bgp_route_propagation_enabled = !try(each.value.disable_bgp_route_propagation, false)

  tags = local.tags
}

# NSG-Subnet Associations
resource "azurerm_subnet_network_security_group_association" "nsg_associations" {
  for_each = {
    for assoc in local.nsg_subnet_associations : "${assoc.subnet_key}-${assoc.nsg_key}" => assoc
  }

  subnet_id                 = azurerm_subnet.subnets[each.value.subnet_key].id
  network_security_group_id = azurerm_network_security_group.nsgs[each.value.nsg_key].id
}

# Route Table-Subnet Associations
resource "azurerm_subnet_route_table_association" "rt_associations" {
  for_each = {
    for assoc in local.rt_subnet_associations : "${assoc.subnet_key}-${assoc.rt_key}" => assoc
  }

  subnet_id      = azurerm_subnet.subnets[each.value.subnet_key].id
  route_table_id = azurerm_route_table.route_tables[each.value.rt_key].id
}

# Local values for associations
locals {
  nsg_subnet_associations = flatten([
    for subnet_key, subnet in var.subnets : [
      for nsg_key in try(subnet.network_security_group_keys, []) : {
        subnet_key = subnet_key
        nsg_key    = nsg_key
      }
    ]
  ])

  rt_subnet_associations = flatten([
    for subnet_key, subnet in var.subnets : [
      for rt_key in try(subnet.route_table_keys, []) : {
        subnet_key = subnet_key
        rt_key     = rt_key
      }
    ]
  ])
}

# Resource Lock
resource "azurerm_management_lock" "vnet_lock" {
  count = var.enable_resource_lock ? 1 : 0

  name       = "${local.vnet_name}-lock"
  scope      = azurerm_virtual_network.main.id
  lock_level = var.lock_level
  notes      = "Resource lock for Virtual Network"
}