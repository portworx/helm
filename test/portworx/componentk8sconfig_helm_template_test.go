package portworx_test

import (
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	test_utils "github.com/portworx/helm/test/utils"
	"github.com/stretchr/testify/require"
)

func TestComponentK8sConfigHelmTemplate(t *testing.T) {

	t.Parallel()

	// Path to the helm chart we will test
	helmChartPath, err := filepath.Abs("../../charts/portworx/")
	// name of template that we want to test
	templateFileName := "component-k8s-config.yaml"
	require.NoError(t, err)

	testCases := []struct {
		name             string
		helmOption       *helm.Options
		resultFileName   string
		expectedErrorMsg string
	}{
		{
			name:           "componentK8sConfig",
			resultFileName: "componentk8sconfigs.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/componentk8sconfigs.yaml"},
			},
		},
		{
			name:           "componentK8sConfigGlobalConfigPriorityClass",
			resultFileName: "componentk8sconfig_global_config_priority_class.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/componentk8sconfig_global_config_priority_class.yaml"},
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
