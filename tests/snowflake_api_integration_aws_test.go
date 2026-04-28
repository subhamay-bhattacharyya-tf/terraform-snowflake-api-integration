// File: tests/snowflake_api_integration_aws_test.go
//
// End-to-end Terratest for examples/aws-api-gateway. Creates a real
// Snowflake AWS API Gateway integration, asserts its presence and outputs,
// runs terraform plan to verify idempotency, then destroys.
package tests

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	awsMapKey      = "aws_api_gw"
	awsProvider    = "AWS_API_GATEWAY"
	awsTestRoleArn = "arn:aws:iam::123456789012:role/snowflake-api-role"
)

// TestSnowflakeApiIntegrationAws exercises examples/aws-api-gateway against
// a real Snowflake account.
func TestSnowflakeApiIntegrationAws(t *testing.T) {
	t.Parallel()

	suffix := uniqueSuffix(t)
	integrationName := fmt.Sprintf("TT_AWS_API_INT_%s", suffix)

	apiIntegrationConfigs := map[string]interface{}{
		awsMapKey: map[string]interface{}{
			"name":             integrationName,
			"api_provider":     "aws_api_gateway",
			"api_aws_role_arn": awsTestRoleArn,
			"api_allowed_prefixes": []string{
				"https://abc123.execute-api.us-east-1.amazonaws.com/prod/",
			},
			"api_blocked_prefixes": []string{
				"https://abc123.execute-api.us-east-1.amazonaws.com/prod/admin/",
			},
			"enabled": true,
			"comment": "Terratest Snowflake AWS API Gateway integration.",
		},
	}

	opts := buildTerraformOptions(t, "../examples/aws-api-gateway")
	opts.Vars["api_integration_configs"] = apiIntegrationConfigs

	defer terraform.Destroy(t, opts)

	terraform.InitAndApply(t, opts)

	// 1. Output assertions -- only the non-sensitive maps. The sensitive
	// `api_integrations` map carries the AWS IAM user ARN / external ID and
	// is verified out-of-band against Snowflake below.
	names := terraform.OutputMap(t, opts, "api_integration_names")
	require.Contains(t, names, awsMapKey)
	assert.Equal(t, integrationName, names[awsMapKey])

	fqNames := terraform.OutputMap(t, opts, "api_integration_fully_qualified_names")
	require.Contains(t, fqNames, awsMapKey)
	assert.NotEmpty(t, fqNames[awsMapKey],
		"api_integration_fully_qualified_names[%q] should be non-empty", awsMapKey)

	// 2. Snowflake-side verification.
	time.Sleep(5 * time.Second)
	db := newSnowflakeClient(t)
	defer func() { _ = db.Close() }()

	assertApiIntegrationExists(t, db, integrationName)
	assertApiIntegrationProvider(t, db, integrationName, awsProvider)
	assertApiIntegrationEnabled(t, db, integrationName, true)

	// 3. Idempotency: plan after apply should be a no-op.
	planOut := terraform.InitAndPlan(t, opts)
	assert.Contains(t, planOut, "No changes",
		"terraform plan after apply should report no changes for Snowflake API integration %q",
		integrationName)
}
