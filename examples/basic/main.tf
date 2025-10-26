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
  name     = "rg-vnet-basic-example"
  location = "westeurope"
}

module "virtual_network" {
  source = "../.."

  name                = "vnet-basic-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  environment         = "test"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "default" = {
      address_prefixes = ["10.0.1.0/24"]
    }
  }

  tags = {
    Example = "Basic"
  }
}

output "virtual_network_name" {
  value = module.virtual_network.name
}

output "subnet_ids" {
  value = module.virtual_network.subnet_ids
}