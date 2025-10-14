package portworx_test

import (
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/stretchr/testify/require"

	test_utils "github.com/portworx/helm/test/utils"
)

func TestPortworxOperatorHelmTemplate(t *testing.T) {
	t.Parallel()

	// Path to the helm chart we will test
	helmChartPath, err := filepath.Abs("../../charts/portworx/")
	// name of template that we want to test
	templateFileName := "portworx-operator.yaml"
	require.NoError(t, err)

	testCases := []struct {
		name             string
		resultFileName   string
		helmOption       *helm.Options
		expectedErrorMsg string
	}{
		{
			name:           "TestVerboseOperatorLogEnabled",
			resultFileName: "portworx_operator_verbose_enabled.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"verboseOperatorLog": "true",
					"internalKVDB":       "true",
				},
			},
		},
		{
			name:           "TestVerboseOperatorLogDisabled",
			resultFileName: "portworx_operator_verbose_disabled.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"verboseOperatorLog": "false",
					"internalKVDB":       "true",
				},
			},
		},
	}

	for _, testCase := range testCases {
		testCase := testCase

		t.Run(testCase.name, func(t *testing.T) {
			t.Parallel()
			resultFilePath, err := filepath.Abs(filepath.Join("testspec/", testCase.resultFileName))
			require.NoError(t, err)
			test_utils.TestRenderedHelmTemplate(t, testCase.helmOption, helmChartPath, templateFileName, resultFilePath, testCase.expectedErrorMsg)
		})
	}
}