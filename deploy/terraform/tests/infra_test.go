// Infrastructure tests using Terratest.
// Run: go test -v -timeout 30m ./deploy/terraform/tests/

package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestNetworkingModule(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: "../modules/networking",
		Vars: map[string]interface{}{
			"environment": "test",
			"vpc_cidr":    "10.99.0.0/16",
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	vpcID := terraform.Output(t, opts, "vpc_id")
	assert.NotEmpty(t, vpcID)

	privateSubnets := terraform.OutputList(t, opts, "private_subnet_ids")
	assert.Equal(t, 2, len(privateSubnets))
}

func TestRegistryModule(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: "../modules/registry",
		Vars: map[string]interface{}{
			"environment": "test",
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	repoURL := terraform.Output(t, opts, "repository_url")
	assert.Contains(t, repoURL, "bluecollar-api")
}
