variable "name" {
  description = "Name of the Virtual Network. If null, will be auto-generated."
  type        = string
  default     = null
}

variable "naming_prefix" {
  description = "Prefix for Virtual Network naming"
  type        = string
  default     = "vnet"
}

variable "environment" {
  description = "Environment name (e.g., prod, dev, test)"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  validation {
    condition     = alltrue([for cidr in var.address_space : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/([0-9]|[1-2][0-9]|3[0-2])$", cidr))])
    error_message = "Address space must be valid CIDR blocks."
  }
}

variable "dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
  default     = null
}

variable "ddos_protection_plan_id" {
  description = "ID of DDoS Protection Plan"
  type        = string
  default     = null
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection"
  type        = bool
  default     = false
}

variable "encryption_enforcement" {
  description = "Encryption enforcement setting"
  type        = string
  default     = "Unencrypted"
  validation {
    condition     = contains(["Unencrypted", "AllowUnencrypted", "DropUnencrypted"], var.encryption_enforcement)
    error_message = "Must be Unencrypted, AllowUnencrypted, or DropUnencrypted."
  }
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])

    delegations = optional(list(object({
      name         = string
      service_name = string
      actions      = optional(list(string), [])
    })), [])

    private_endpoint_network_policies_enabled     = optional(bool, true)
    private_link_service_network_policies_enabled = optional(bool, true)

    network_security_group_keys = optional(list(string), [])
    route_table_keys            = optional(list(string), [])

    # Flow logs configuration
    enable_flow_logs           = optional(bool, false)
    flow_logs_retention_days   = optional(number, 30)
    enable_traffic_analytics   = optional(bool, false)
    traffic_analytics_interval = optional(number, 60)
  }))
  default = {}
}

variable "network_security_groups" {
  description = "Map of Network Security Groups to create"
  type = map(object({
    security_rules = optional(list(object({
      name                                       = string
      priority                                   = number
      direction                                  = string
      access                                     = string
      protocol                                   = string
      source_port_range                          = optional(string)
      source_port_ranges                         = optional(list(string))
      destination_port_range                     = optional(string)
      destination_port_ranges                    = optional(list(string))
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(list(string))
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(list(string))
      source_application_security_group_ids      = optional(list(string))
      destination_application_security_group_ids = optional(list(string))
    })), [])
  }))
  default = {}
}

variable "route_tables" {
  description = "Map of Route Tables to create"
  type = map(object({
    disable_bgp_route_propagation = optional(bool, false)
    routes = optional(list(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), [])
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "create_resource_group" {
  description = "Create resource group if it doesn't exist"
  type        = bool
  default     = false
}

variable "nat_gateways" {
  description = "Map of NAT Gateways to create"
  type = map(object({
    sku_name                = optional(string, "Standard")
    idle_timeout_in_minutes = optional(number, 4)
    zones                   = optional(list(string), [])
    public_ip = optional(object({
      allocation_method = optional(string, "Static")
      sku               = optional(string, "Standard")
      zones             = optional(list(string), [])
    }))
  }))
  default = {}
}

variable "enable_network_watcher" {
  description = "Enable Network Watcher for the region"
  type        = bool
  default     = false
}

variable "flow_logs_storage_account_id" {
  description = "Storage Account ID for Flow Logs"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostics and traffic analytics"
  type        = string
  default     = null
}

variable "log_analytics_workspace_resource_id" {
  description = "Log Analytics Workspace Resource ID for traffic analytics"
  type        = string
  default     = null
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for Virtual Network"
  type        = bool
  default     = true
}

variable "diagnostic_settings" {
  description = "Diagnostic settings configuration"
  type = object({
    logs = list(object({
      category = string
    }))
    metrics = list(object({
      category = string
      enabled  = bool
    }))
  })
  default = {
    logs = [
      { category = "VMProtectionAlerts" }
    ]
    metrics = [
      { category = "AllMetrics", enabled = true }
    ]
  }
}

variable "enable_resource_lock" {
  description = "Enable resource lock for Virtual Network"
  type        = bool
  default     = false
}

variable "lock_level" {
  description = "Resource lock level: CanNotDelete or ReadOnly"
  type        = string
  default     = "CanNotDelete"
  validation {
    condition     = contains(["CanNotDelete", "ReadOnly"], var.lock_level)
    error_message = "Lock level must be CanNotDelete or ReadOnly."
  }
}