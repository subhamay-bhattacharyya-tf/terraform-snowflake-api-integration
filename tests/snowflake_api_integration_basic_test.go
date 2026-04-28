// File: tests/snowflake_api_integration_basic_test.go
//
// End-to-end Terratest for examples/basic. Creates a real Snowflake API
// integration, asserts its presence and outputs, runs terraform plan to
// verify idempotency, then destroys.
package tests

import (
	"fmt"
	"regexp"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	basicMapKey      = "aws_api_gw"
	basicProvider    = "AWS_API_GATEWAY"
	basicAwsRoleArn  = "arn:aws:iam::123456789012:role/snowflake-api-role"
	awsIamUserArnRgx = `^arn:aws[a-zA-Z-]*:iam::\d{12}:user\/.+$`
)

// TestSnowflakeApiIntegrationBasic exercises the examples/basic configuration
// against a real Snowflake account.
func TestSnowflakeApiIntegrationBasic(t *testing.T) {
	t.Parallel()

	suffix := uniqueSuffix(t)
	integrationName := fmt.Sprintf("TT_AWS_API_INT_%s", suffix)

	apiIntegrations := map[string]interface{}{
		basicMapKey: map[string]interface{}{
			"name":             integrationName,
			"api_provider":     "aws_api_gateway",
			"api_aws_role_arn": basicAwsRoleArn,
			"api_allowed_prefixes": []string{
				"https://abc123.execute-api.us-east-1.amazonaws.com/prod/",
			},
			"api_blocked_prefixes": []string{
				"https://abc123.execute-api.us-east-1.amazonaws.com/prod/admin/",
			},
			"enabled": true,
			"comment": "Terratest Snowflake API integration (basic).",
		},
	}

	opts := buildTerraformOptions(t, "../examples/basic")
	opts.Vars["api_integrations"] = apiIntegrations

	// Always destroy on teardown to avoid leaking API integrations.
	defer terraform.Destroy(t, opts)

	terraform.InitAndApply(t, opts)

	// 1. Output assertions
	ids := terraform.OutputMap(t, opts, "api_integration_ids")
	require.Contains(t, ids, basicMapKey, "api_integration_ids should contain map key %q", basicMapKey)
	assert.NotEmpty(t, ids[basicMapKey], "api_integration_ids[%q] should be non-empty", basicMapKey)

	names := terraform.OutputMap(t, opts, "api_integration_names")
	require.Contains(t, names, basicMapKey)
	assert.Equal(t, integrationName, names[basicMapKey])

	providers := terraform.OutputMap(t, opts, "api_integration_providers")
	require.Contains(t, providers, basicMapKey)
	assert.Equal(t, basicProvider, providers[basicMapKey])

	awsUserArns := terraform.OutputMap(t, opts, "api_aws_iam_user_arns")
	require.Contains(t, awsUserArns, basicMapKey)
	assert.Regexp(t, regexp.MustCompile(awsIamUserArnRgx), awsUserArns[basicMapKey],
		"api_aws_iam_user_arns[%q] should match the IAM user ARN pattern", basicMapKey)

	// 2. Snowflake-side verification
	time.Sleep(5 * time.Second)
	db := newSnowflakeClient(t)
	defer func() { _ = db.Close() }()

	assertApiIntegrationExists(t, db, integrationName)
	assertApiIntegrationProvider(t, db, integrationName, basicProvider)
	assertApiIntegrationEnabled(t, db, integrationName, true)

	// 3. Idempotency: plan after apply should be a no-op
	planOut := terraform.InitAndPlan(t, opts)
	assert.Contains(t, planOut, "No changes",
		"terraform plan after apply should report no changes for Snowflake API integration %q",
		integrationName)
}
