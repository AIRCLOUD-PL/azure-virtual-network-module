terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-vnet-complete-example"
  location = "westeurope"
}

module "virtual_network" {
  source = "../.."

  name                = "vnet-complete-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  environment         = "test"
  address_space       = ["10.0.0.0/16", "10.1.0.0/16"]

  # DNS Configuration
  dns_servers = ["168.63.129.16", "8.8.8.8"]

  subnets = {
    "web" = {
      address_prefixes            = ["10.0.1.0/24"]
      service_endpoints           = ["Microsoft.Storage", "Microsoft.Sql"]
      network_security_group_keys = ["web-nsg"]
      route_table_keys            = ["web-rt"]
    }

    "app" = {
      address_prefixes            = ["10.0.2.0/24"]
      network_security_group_keys = ["app-nsg"]
      route_table_keys            = ["app-rt"]
    }

    "db" = {
      address_prefixes            = ["10.0.3.0/24"]
      network_security_group_keys = ["db-nsg"]
      delegations = [
        {
          name         = "sql-delegation"
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
          name         = "aks-delegation"
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
    Example = "Complete"
  }
}

output "virtual_network_id" {
  value = module.virtual_network.id
}

output "subnet_ids" {
  value = module.virtual_network.subnet_ids
}

output "network_security_group_ids" {
  value = module.virtual_network.network_security_group_ids
}

output "route_table_ids" {
  value = module.virtual_network.route_table_ids
}