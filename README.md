<p align="center">
  <a href="https://aircloud.com.pl"><img src=".github/assets/banner.png" alt="AIRCLOUD: DevOps, cloud and AI engineering" width="100%"></a>
</p>

# azure-virtual-network-module

**Azure Virtual Network Terraform module — parameterised, azurerm 4.x, CI-validated.**

[![CI](https://github.com/AIRCLOUD-PL/azure-virtual-network-module/actions/workflows/ci.yml/badge.svg)](https://github.com/AIRCLOUD-PL/azure-virtual-network-module/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/AIRCLOUD-PL/azure-virtual-network-module?sort=semver)](https://github.com/AIRCLOUD-PL/azure-virtual-network-module/releases)

Enterprise-grade Azure Virtual Network module with comprehensive networking and security features.

## Features

✅ **Multi-Address Space** - Support for multiple CIDR blocks  
✅ **Advanced Subnets** - Delegations, service endpoints, private endpoints  
✅ **Security Groups** - NSGs with granular security rules  
✅ **Route Tables** - Custom routing with BGP integration  
✅ **DDoS Protection** - Azure DDoS Protection Standard  
✅ **Encryption** - VNet encryption support  
✅ **DNS Configuration** - Custom DNS servers  
✅ **Azure Policy** - Compliance and security enforcement  

## Usage

Pin the module to a release tag:

```hcl
module "virtual_network" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-virtual-network-module.git?ref=v1.0.0"

  # required inputs
  address_space       = []
  environment         = "..."
  location            = "..."
  resource_group_name = "..."
}
```

All inputs and outputs are listed in the generated reference below ([Inputs](#inputs), [Outputs](#outputs)). Worked examples live in [`examples/`](examples/).

### Basic Example

```hcl
module "virtual_network" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-virtual-network-module.git?ref=v1.0.0"

  name                = "vnet-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = "rg-production"
  environment         = "prod"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "default" = {
      address_prefixes = ["10.0.1.0/24"]
    }
  }

  tags = {
    Environment = "Production"
  }
}
```

### Complete Example with Security

```hcl
module "virtual_network" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-virtual-network-module.git?ref=v1.0.0"

  name                = "vnet-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = "rg-production"
  environment         = "prod"
  address_space       = ["10.0.0.0/16", "10.1.0.0/16"]

  # DNS Configuration
  dns_servers = ["168.63.129.16", "8.8.8.8"]

  # DDoS Protection
  enable_ddos_protection = true
  ddos_protection_plan_id = azurerm_network_ddos_protection_plan.main.id

  # Encryption
  encryption_enforcement = "AllowUnencrypted"

  subnets = {
    "web" = {
      address_prefixes = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
      network_security_group_keys = ["web-nsg"]
      route_table_keys = ["web-rt"]
    }

    "app" = {
      address_prefixes = ["10.0.2.0/24"]
      network_security_group_keys = ["app-nsg"]
      route_table_keys = ["app-rt"]
    }

    "db" = {
      address_prefixes = ["10.0.3.0/24"]
      network_security_group_keys = ["db-nsg"]
      delegations = [
        {
          name = "sql-delegation"
          service_name = "Microsoft.Sql/managedInstances"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action",
            "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
            "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
          ]
        }
      ]
    }

    "aks" = {
      address_prefixes = ["10.0.4.0/24"]
      delegations = [
        {
          name = "aks-delegation"
          service_name = "Microsoft.ContainerService/managedClusters"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      ]
    }
  }

  network_security_groups = {
    "web-nsg" = {
      security_rules = [
        {
          name                       = "AllowHTTP"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowHTTPS"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }

    "app-nsg" = {
      security_rules = [
        {
          name                       = "AllowFromWeb"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "8080"
          source_address_prefix      = "10.0.1.0/24"
          destination_address_prefix = "*"
        }
      ]
    }

    "db-nsg" = {
      security_rules = [
        {
          name                       = "AllowFromApp"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "1433"
          source_address_prefix      = "10.0.2.0/24"
          destination_address_prefix = "*"
        }
      ]
    }
  }

  route_tables = {
    "web-rt" = {
      routes = [
        {
          name           = "ToInternet"
          address_prefix = "0.0.0.0/0"
          next_hop_type  = "Internet"
        }
      ]
    }

    "app-rt" = {
      disable_bgp_route_propagation = true
      routes = [
        {
          name                   = "ToFirewall"
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.0.100.4"
        }
      ]
    }
  }

  tags = {
    Environment = "Production"
    Security    = "High"
    Compliance  = "SOX"
  }
}
```

## Examples

- [Basic](./examples/basic/) - Simple VNet with one subnet
- [Complete](./examples/complete/) - Full enterprise networking setup
- [Hub-Spoke](examples/) - Hub and spoke topology

## Security Features

### Network Security
- **NSG Rules** - Granular inbound/outbound filtering
- **Service Endpoints** - Secure service access without public IPs
- **Private Endpoints** - Private connectivity to Azure services
- **Route Tables** - Custom routing and traffic control

### Compliance & Governance
- **Azure Policy** - Automated compliance enforcement
- **DDoS Protection** - Advanced DDoS mitigation
- **Network Encryption** - VNet traffic encryption
- **Delegation Support** - Service-specific subnet delegation

### Monitoring & Management
- **Network Watcher** - Network monitoring and diagnostics
- **Flow Logs** - NSG flow logging
- **Traffic Analytics** - Network traffic insights

## Version

Current version: **v1.0.0**

## License

MIT

## Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.81.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_management_lock.vnet_lock](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_monitor_diagnostic_setting.vnet_diagnostics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_nat_gateway.nat_gateways](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway) | resource |
| [azurerm_nat_gateway_public_ip_association.nat_pip_associations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association) | resource |
| [azurerm_network_ddos_protection_plan.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_ddos_protection_plan) | resource |
| [azurerm_network_security_group.nsgs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_watcher.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher) | resource |
| [azurerm_network_watcher_flow_log.flow_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher_flow_log) | resource |
| [azurerm_public_ip.nat_pips](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_resource_group_policy_assignment.no_rdp_from_internet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_resource_group_policy_assignment.no_ssh_from_internet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_resource_group_policy_assignment.nsg_on_subnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_route_table.route_tables](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_subnet.subnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.nsg_associations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_route_table_association.rt_associations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | Address space for the Virtual Network | `list(string)` | n/a | yes |
| <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group) | Create resource group if it doesn't exist | `bool` | `false` | no |
| <a name="input_ddos_protection_plan_id"></a> [ddos\_protection\_plan\_id](#input\_ddos\_protection\_plan\_id) | ID of DDoS Protection Plan | `string` | `null` | no |
| <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings) | Diagnostic settings configuration | <pre>object({<br/>    logs = list(object({<br/>      category = string<br/>    }))<br/>    metrics = list(object({<br/>      category = string<br/>      enabled  = bool<br/>    }))<br/>  })</pre> | <pre>{<br/>  "logs": [<br/>    {<br/>      "category": "VMProtectionAlerts"<br/>    }<br/>  ],<br/>  "metrics": [<br/>    {<br/>      "category": "AllMetrics",<br/>      "enabled": true<br/>    }<br/>  ]<br/>}</pre> | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | List of DNS servers | `list(string)` | `null` | no |
| <a name="input_enable_ddos_protection"></a> [enable\_ddos\_protection](#input\_enable\_ddos\_protection) | Enable DDoS Protection | `bool` | `false` | no |
| <a name="input_enable_diagnostic_settings"></a> [enable\_diagnostic\_settings](#input\_enable\_diagnostic\_settings) | Enable diagnostic settings for Virtual Network | `bool` | `true` | no |
| <a name="input_enable_network_watcher"></a> [enable\_network\_watcher](#input\_enable\_network\_watcher) | Enable Network Watcher for the region | `bool` | `false` | no |
| <a name="input_enable_policy_assignments"></a> [enable\_policy\_assignments](#input\_enable\_policy\_assignments) | Enable Azure Policy assignments for this Virtual Network | `bool` | `true` | no |
| <a name="input_enable_resource_lock"></a> [enable\_resource\_lock](#input\_enable\_resource\_lock) | Enable resource lock for Virtual Network | `bool` | `false` | no |
| <a name="input_encryption_enforcement"></a> [encryption\_enforcement](#input\_encryption\_enforcement) | Encryption enforcement setting | `string` | `"Unencrypted"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., prod, dev, test) | `string` | n/a | yes |
| <a name="input_flow_logs_storage_account_id"></a> [flow\_logs\_storage\_account\_id](#input\_flow\_logs\_storage\_account\_id) | Storage Account ID for Flow Logs | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources will be created | `string` | n/a | yes |
| <a name="input_lock_level"></a> [lock\_level](#input\_lock\_level) | Resource lock level: CanNotDelete or ReadOnly | `string` | `"CanNotDelete"` | no |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics Workspace ID for diagnostics and traffic analytics | `string` | `null` | no |
| <a name="input_log_analytics_workspace_resource_id"></a> [log\_analytics\_workspace\_resource\_id](#input\_log\_analytics\_workspace\_resource\_id) | Log Analytics Workspace Resource ID for traffic analytics | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Virtual Network. If null, will be auto-generated. | `string` | `null` | no |
| <a name="input_naming_prefix"></a> [naming\_prefix](#input\_naming\_prefix) | Prefix for Virtual Network naming | `string` | `"vnet"` | no |
| <a name="input_nat_gateways"></a> [nat\_gateways](#input\_nat\_gateways) | Map of NAT Gateways to create | <pre>map(object({<br/>    sku_name                = optional(string, "Standard")<br/>    idle_timeout_in_minutes = optional(number, 4)<br/>    zones                   = optional(list(string), [])<br/>    public_ip = optional(object({<br/>      allocation_method = optional(string, "Static")<br/>      sku               = optional(string, "Standard")<br/>      zones             = optional(list(string), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_network_security_groups"></a> [network\_security\_groups](#input\_network\_security\_groups) | Map of Network Security Groups to create | <pre>map(object({<br/>    security_rules = optional(list(object({<br/>      name                                       = string<br/>      priority                                   = number<br/>      direction                                  = string<br/>      access                                     = string<br/>      protocol                                   = string<br/>      source_port_range                          = optional(string)<br/>      source_port_ranges                         = optional(list(string))<br/>      destination_port_range                     = optional(string)<br/>      destination_port_ranges                    = optional(list(string))<br/>      source_address_prefix                      = optional(string)<br/>      source_address_prefixes                    = optional(list(string))<br/>      destination_address_prefix                 = optional(string)<br/>      destination_address_prefixes               = optional(list(string))<br/>      source_application_security_group_ids      = optional(list(string))<br/>      destination_application_security_group_ids = optional(list(string))<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_route_tables"></a> [route\_tables](#input\_route\_tables) | Map of Route Tables to create | <pre>map(object({<br/>    disable_bgp_route_propagation = optional(bool, false)<br/>    routes = optional(list(object({<br/>      name                   = string<br/>      address_prefix         = string<br/>      next_hop_type          = string<br/>      next_hop_in_ip_address = optional(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Map of subnets to create | <pre>map(object({<br/>    address_prefixes  = list(string)<br/>    service_endpoints = optional(list(string), [])<br/><br/>    delegations = optional(list(object({<br/>      name         = string<br/>      service_name = string<br/>      actions      = optional(list(string), [])<br/>    })), [])<br/><br/>    private_endpoint_network_policies_enabled     = optional(bool, true)<br/>    private_link_service_network_policies_enabled = optional(bool, true)<br/><br/>    network_security_group_keys = optional(list(string), [])<br/>    route_table_keys            = optional(list(string), [])<br/><br/>    # Flow logs configuration<br/>    enable_flow_logs           = optional(bool, false)<br/>    flow_logs_retention_days   = optional(number, 30)<br/>    enable_traffic_analytics   = optional(bool, false)<br/>    traffic_analytics_interval = optional(number, 60)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_address_space"></a> [address\_space](#output\_address\_space) | Virtual Network address space |
| <a name="output_id"></a> [id](#output\_id) | Virtual Network resource ID |
| <a name="output_name"></a> [name](#output\_name) | Virtual Network name |
| <a name="output_network_security_group_ids"></a> [network\_security\_group\_ids](#output\_network\_security\_group\_ids) | Map of NSG names to IDs |
| <a name="output_route_table_ids"></a> [route\_table\_ids](#output\_route\_table\_ids) | Map of Route Table names to IDs |
| <a name="output_subnet_address_prefixes"></a> [subnet\_address\_prefixes](#output\_subnet\_address\_prefixes) | Map of subnet names to address prefixes |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Map of subnet names to IDs |
| <a name="output_vnet_guid"></a> [vnet\_guid](#output\_vnet\_guid) | Virtual Network GUID |
<!-- END_TF_DOCS -->

---

## Part of the AIRCLOUD Azure module catalog

Browse all modules with usage snippets in the [module catalog](https://aircloud-pl.github.io/) or on [github.com/AIRCLOUD-PL](https://github.com/AIRCLOUD-PL). Built and maintained by [AIRCLOUD](https://aircloud.com.pl): DevOps, cloud and AI engineering. Need a hand with Azure landing zones or platform engineering? See [aircloud.com.pl/consulting](https://aircloud.com.pl/consulting).
