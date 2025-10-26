/**
 * Security configurations and policies for Virtual Network
 */

# Azure Policy - Require NSG on subnets
resource "azurerm_resource_group_policy_assignment" "nsg_on_subnets" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "${azurerm_virtual_network.main.name}-nsg-on-subnets"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/6c112d4e-5bc7-47ae-a041-ea2d9dccd749"
  display_name         = "Subnets should have a Network Security Group"
  description          = "Ensures all subnets have NSG protection"

  parameters = jsonencode({
    effect = {
      value = "AuditIfNotExists"
    }
  })
}

# Azure Policy - Disable RDP from Internet
resource "azurerm_resource_group_policy_assignment" "no_rdp_from_internet" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "${azurerm_virtual_network.main.name}-no-rdp-internet"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e372f862-24f3-4f01-8c5c-9e8c5c8e4e9a"
  display_name         = "RDP access from the Internet should be blocked"
  description          = "Blocks RDP access from the Internet"

  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })
}

# Azure Policy - Disable SSH from Internet
resource "azurerm_resource_group_policy_assignment" "no_ssh_from_internet" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "${azurerm_virtual_network.main.name}-no-ssh-internet"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2c89a2e5-7285-40fe-afe0-ae8654b92fb2"
  display_name         = "SSH access from the Internet should be blocked"
  description          = "Blocks SSH access from the Internet"

  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })
}

# Data source for resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Variables for policies
variable "enable_policy_assignments" {
  description = "Enable Azure Policy assignments for this Virtual Network"
  type        = bool
  default     = true
}