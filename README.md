# Azure Virtual Network Terraform Module

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

### Basic Example

```hcl
module "virtual_network" {
  source = "github.com/AIRCLOUD-PL/terraform-azurerm-virtual-network?ref=v1.0.0"

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
  source = "github.com/AIRCLOUD-PL/terraform-azurerm-virtual-network?ref=v1.0.0"

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

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | >= 3.80.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.80.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| address_space | VNet address space | `list(string)` | n/a | yes |
| name | VNet name | `string` | `null` | no |
| subnets | Subnet configuration | `map(object)` | `{}` | no |
| network_security_groups | NSG configuration | `map(object)` | `{}` | no |
| route_tables | Route table configuration | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Virtual Network ID |
| name | Virtual Network name |
| address_space | VNet address space |
| subnet_ids | Map of subnet IDs |
| network_security_group_ids | Map of NSG IDs |
| route_table_ids | Map of Route Table IDs |

## Examples

- [Basic](./examples/basic/) - Simple VNet with one subnet
- [Complete](./examples/complete/) - Full enterprise networking setup
- [Hub-Spoke](./examples/hub-spoke/) - Hub and spoke topology

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
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
