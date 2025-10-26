package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestVirtualNetworkModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",

		Vars: map[string]interface{}{
			"resource_group_name": "rg-test-vnet-basic",
			"location":           "westeurope",
			"environment":        "test",
			"address_space":      []string{"10.0.0.0/16"},
			"subnets": map[string]interface{}{
				"default": map[string]interface{}{
					"address_prefixes": []string{"10.0.1.0/24"},
				},
			},
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_virtual_network.main")
}

func TestVirtualNetworkModuleWithSecurity(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",

		Vars: map[string]interface{}{
			"resource_group_name": "rg-test-vnet-security",
			"location":           "westeurope",
			"environment":        "test",
			"address_space":      []string{"10.0.0.0/16"},
			"subnets": map[string]interface{}{
				"web": map[string]interface{}{
					"address_prefixes": []string{"10.0.1.0/24"},
					"network_security_group_keys": []string{"web-nsg"},
				},
				"app": map[string]interface{}{
					"address_prefixes": []string{"10.0.2.0/24"},
					"network_security_group_keys": []string{"app-nsg"},
				},
			},
			"network_security_groups": map[string]interface{}{
				"web-nsg": map[string]interface{}{
					"security_rules": []map[string]interface{}{
						{
							"name":                       "AllowHTTP",
							"priority":                   100,
							"direction":                  "Inbound",
							"access":                     "Allow",
							"protocol":                   "Tcp",
							"source_port_range":          "*",
							"destination_port_range":     "80",
							"source_address_prefix":      "*",
							"destination_address_prefix": "*",
						},
					},
				},
				"app-nsg": map[string]interface{}{
					"security_rules": []map[string]interface{}{
						{
							"name":                       "DenyAllInbound",
							"priority":                   100,
							"direction":                  "Inbound",
							"access":                     "Deny",
							"protocol":                   "*",
							"source_port_range":          "*",
							"destination_port_range":     "*",
							"source_address_prefix":      "*",
							"destination_address_prefix": "*",
						},
					},
				},
			},
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_network_security_group.nsgs")
}

func TestVirtualNetworkModuleNamingConvention(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",

		Vars: map[string]interface{}{
			"resource_group_name": "rg-test-vnet-naming",
			"location":           "westeurope",
			"environment":        "prod",
			"naming_prefix":      "vnetprod",
			"address_space":      []string{"10.0.0.0/16"},
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	resourceChanges := terraform.GetResourceChanges(t, planStruct)

	for _, change := range resourceChanges {
		if change.Type == "azurerm_virtual_network" && change.Change.After != nil {
			afterMap := change.Change.After.(map[string]interface{})
			if name, ok := afterMap["name"]; ok {
				vnetName := name.(string)
				assert.Contains(t, vnetName, "prod", "VNet name should contain environment")
			}
		}
	}
}

func TestVirtualNetworkModuleWithDelegations(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",

		Vars: map[string]interface{}{
			"resource_group_name": "rg-test-vnet-delegations",
			"location":           "westeurope",
			"environment":        "test",
			"address_space":      []string{"10.0.0.0/16"},
			"subnets": map[string]interface{}{
				"aks": map[string]interface{}{
					"address_prefixes": []string{"10.0.1.0/24"},
					"delegations": []map[string]interface{}{
						{
							"name":         "aks-delegation",
							"service_name": "Microsoft.ContainerService/managedClusters",
							"actions": []string{
								"Microsoft.Network/virtualNetworks/subnets/join/action",
							},
						},
					},
				},
			},
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_subnet.subnets")
}