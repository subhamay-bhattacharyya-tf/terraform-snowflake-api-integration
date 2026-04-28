// File: tests/helpers_test.go
//
// Pure setup/teardown/assertion primitives for Snowflake API integration
// tests. Test files under tests/ should call these helpers rather than
// re-implementing connection or query logic.
package tests

import (
	"crypto/rsa"
	"crypto/x509"
	"database/sql"
	"encoding/pem"
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/snowflakedb/gosnowflake"
	"github.com/stretchr/testify/require"
)

// buildTerraformOptions constructs a *terraform.Options pointed at the given
// example directory and wired with the SNOWFLAKE_* env vars used by the
// example's provider configuration. Skips the test if the credentials needed
// to actually reach Snowflake aren't set, so CI runs without secrets (or
// fork PRs that can't read secrets) don't masquerade as real Terratest runs.
func buildTerraformOptions(t *testing.T, exampleDir string) *terraform.Options {
	t.Helper()

	required := []string{
		"SNOWFLAKE_ORGANIZATION_NAME",
		"SNOWFLAKE_ACCOUNT_NAME",
		"SNOWFLAKE_USER",
		"SNOWFLAKE_PRIVATE_KEY",
	}
	for _, key := range required {
		if strings.TrimSpace(os.Getenv(key)) == "" {
			t.Skipf("Skipping Terratest: %s is not set; cannot reach Snowflake.", key)
		}
	}

	return &terraform.Options{
		TerraformDir: exampleDir,
		NoColor:      true,
		Vars: map[string]interface{}{
			"snowflake_organization_name": os.Getenv("SNOWFLAKE_ORGANIZATION_NAME"),
			"snowflake_account_name":      os.Getenv("SNOWFLAKE_ACCOUNT_NAME"),
			"snowflake_user":              os.Getenv("SNOWFLAKE_USER"),
			"snowflake_role":              os.Getenv("SNOWFLAKE_ROLE"),
			"snowflake_private_key":       os.Getenv("SNOWFLAKE_PRIVATE_KEY"),
		},
	}
}

// newSnowflakeClient opens an authenticated *sql.DB scoped to the test role
// and warehouse using the same credentials Terraform uses.
func newSnowflakeClient(t *testing.T) *sql.DB {
	t.Helper()

	orgName := mustEnv(t, "SNOWFLAKE_ORGANIZATION_NAME")
	accountName := mustEnv(t, "SNOWFLAKE_ACCOUNT_NAME")
	user := mustEnv(t, "SNOWFLAKE_USER")
	privateKeyPEM := mustEnv(t, "SNOWFLAKE_PRIVATE_KEY")
	role := os.Getenv("SNOWFLAKE_ROLE")
	warehouse := os.Getenv("SNOWFLAKE_WAREHOUSE")

	block, _ := pem.Decode([]byte(privateKeyPEM))
	require.NotNil(t, block, "Failed to decode PEM block from private key")

	var privateKey *rsa.PrivateKey
	key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		privateKey, err = x509.ParsePKCS1PrivateKey(block.Bytes)
		require.NoError(t, err, "Failed to parse private key")
	} else {
		var ok bool
		privateKey, ok = key.(*rsa.PrivateKey)
		require.True(t, ok, "Private key is not RSA")
	}

	config := gosnowflake.Config{
		Account:       fmt.Sprintf("%s-%s", orgName, accountName),
		User:          user,
		Authenticator: gosnowflake.AuthTypeJwt,
		PrivateKey:    privateKey,
	}
	if role != "" {
		config.Role = role
	}
	if warehouse != "" {
		config.Warehouse = warehouse
	}

	dsn, err := gosnowflake.DSN(&config)
	require.NoError(t, err, "Failed to build DSN")

	db, err := sql.Open("snowflake", dsn)
	require.NoError(t, err)
	require.NoError(t, db.Ping())
	return db
}

// assertApiIntegrationExists asserts that an API integration with the given
// name is present in SHOW API INTEGRATIONS.
func assertApiIntegrationExists(t *testing.T, db *sql.DB, name string) {
	t.Helper()
	require.Truef(t, apiIntegrationRowExists(t, db, name),
		"Expected Snowflake API integration %q to exist", name)
}

// assertApiIntegrationDestroyed asserts that an API integration with the
// given name is absent from SHOW API INTEGRATIONS. Used in the post-destroy
// phase to catch leaked resources.
func assertApiIntegrationDestroyed(t *testing.T, db *sql.DB, name string) {
	t.Helper()
	require.Falsef(t, apiIntegrationRowExists(t, db, name),
		"Expected Snowflake API integration %q to be destroyed but it still exists", name)
}

// assertApiIntegrationProvider asserts that the integration's api_provider
// column matches the expected provider (AWS_API_GATEWAY,
// AZURE_API_MANAGEMENT, or GOOGLE_API_GATEWAY).
func assertApiIntegrationProvider(t *testing.T, db *sql.DB, name string, expected string) {
	t.Helper()
	props := fetchApiIntegrationProps(t, db, name)
	require.Equalf(t, strings.ToUpper(expected), strings.ToUpper(props.Provider),
		"Snowflake API integration %q has api_provider=%q, want %q",
		name, props.Provider, expected)
}

// assertApiIntegrationEnabled asserts that the integration's enabled flag
// matches the expected value.
func assertApiIntegrationEnabled(t *testing.T, db *sql.DB, name string, expected bool) {
	t.Helper()
	props := fetchApiIntegrationProps(t, db, name)
	require.Equalf(t, expected, props.Enabled,
		"Snowflake API integration %q has enabled=%v, want %v",
		name, props.Enabled, expected)
}

// uniqueSuffix returns a short, uppercase, alphanumeric suffix derived from
// a random seed. Snowflake identifiers are upper-cased by default. Append
// to integration names to keep parallel runs isolated.
func uniqueSuffix(t *testing.T) string {
	t.Helper()
	return strings.ToUpper(random.UniqueId())
}

// ----- internal helpers -----

type apiIntegrationProps struct {
	Name     string
	Provider string
	Enabled  bool
	Comment  string
}

func apiIntegrationRowExists(t *testing.T, db *sql.DB, name string) bool {
	t.Helper()
	q := fmt.Sprintf("SHOW API INTEGRATIONS LIKE '%s';", escapeLike(name))
	rows, err := db.Query(q)
	require.NoError(t, err)
	defer func() { _ = rows.Close() }()
	return rows.Next()
}

func fetchApiIntegrationProps(t *testing.T, db *sql.DB, name string) apiIntegrationProps {
	t.Helper()

	q := fmt.Sprintf("SHOW API INTEGRATIONS LIKE '%s';", escapeLike(name))
	rows, err := db.Query(q)
	require.NoError(t, err)
	defer func() { _ = rows.Close() }()

	cols, err := rows.Columns()
	require.NoError(t, err)

	idx := map[string]int{}
	for i, c := range cols {
		idx[strings.ToLower(c)] = i
	}

	require.True(t, rows.Next(), "No Snowflake API integration found matching %s", name)

	values := make([]interface{}, len(cols))
	ptrs := make([]interface{}, len(cols))
	for i := range values {
		ptrs[i] = &values[i]
	}
	require.NoError(t, rows.Scan(ptrs...))

	get := func(key string) string {
		i, ok := idx[key]
		if !ok {
			return ""
		}
		v := values[i]
		switch x := v.(type) {
		case nil:
			return ""
		case string:
			return x
		case []byte:
			return string(x)
		default:
			return fmt.Sprintf("%v", x)
		}
	}

	enabledStr := strings.ToLower(get("enabled"))

	return apiIntegrationProps{
		Name:     get("name"),
		Provider: get("api_provider"),
		Enabled:  enabledStr == "true" || enabledStr == "yes" || enabledStr == "1",
		Comment:  get("comment"),
	}
}

func mustEnv(t *testing.T, key string) string {
	t.Helper()
	v := strings.TrimSpace(os.Getenv(key))
	require.NotEmpty(t, v, "Missing required environment variable %s", key)
	return v
}

func escapeLike(s string) string {
	return strings.ReplaceAll(s, "'", "''")
}
