package test

import (
	"fmt"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestAzureVirtualNetworkModule(t *testing.T) {
	t.Parallel()

	MultiTenantTestRunner(t, func(t *testing.T, config TestConfig) {
		SetupAzureAuth(t, config)
		CreateResourceGroup(t, config)
		
		uniqueID := config.UniqueID
		expectedVNetName := fmt.Sprintf("vnet-test-%s", uniqueID)
		
		terraformDir := filepath.Join("..", "..", "modules", "azure-virtual-network-module")
		
		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: terraformDir,
			Vars: map[string]interface{}{
				"vnet_name":          expectedVNetName,
				"location":           config.Region,
				"resource_group_name": fmt.Sprintf("%s-%s", config.ResourceGroup, uniqueID),
				"address_space":      []string{"10.0.0.0/16"},
				"dns_servers":        []string{"8.8.8.8", "8.8.4.4"},
				"subnets": map[string]interface{}{
					"default": map[string]interface{}{
						"address_prefixes": []string{"10.0.1.0/24"},
					},
					"aks": map[string]interface{}{
						"address_prefixes": []string{"10.0.2.0/24"},
					},
					"gateway": map[string]interface{}{
						"address_prefixes": []string{"10.0.3.0/27"},
					},
				},
			},
			EnvVars: map[string]string{
				"ARM_SUBSCRIPTION_ID": config.SubscriptionID,
				"ARM_TENANT_ID":      config.TenantID,
			},
		})

		defer terraform.Destroy(t, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)

		// Validate Virtual Network
		vnetName := terraform.Output(t, terraformOptions, "vnet_name")
		assert.Equal(t, expectedVNetName, vnetName)

		// Validate subnets
		subnets := terraform.OutputMap(t, terraformOptions, "subnet_ids")
		assert.Contains(t, subnets, "default")
		assert.Contains(t, subnets, "aks")
		assert.Contains(t, subnets, "gateway")

		// Get VNet details from Azure
		vnet := azure.GetVirtualNetwork(t, fmt.Sprintf("%s-%s", config.ResourceGroup, uniqueID), vnetName, config.SubscriptionID)
		
		// Validate address space
		assert.Contains(t, *vnet.VirtualNetworkPropertiesFormat.AddressSpace.AddressPrefixes, "10.0.0.0/16")
		
		// Validate DNS servers
		dnsServers := *vnet.VirtualNetworkPropertiesFormat.DhcpOptions.DNSServers
		assert.Contains(t, dnsServers, "8.8.8.8")
		assert.Contains(t, dnsServers, "8.8.4.4")

		// Security compliance validation
		ValidateSecurityCompliance(t, terraformOptions)
		
		// Validate subnets count
		assert.Equal(t, 3, len(*vnet.VirtualNetworkPropertiesFormat.Subnets))
	})
}