package portworx_test

import (
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	test_utils "github.com/portworx/helm/test/utils"
	"github.com/stretchr/testify/require"
)

func TestStorageClusterHelmTemplate(t *testing.T) {

	t.Parallel()

	// Path to the helm chart we will test
	helmChartPath, err := filepath.Abs("../../charts/portworx/")
	// name of template that we want to test
	templateFileName := "storage-cluster.yaml"
	require.NoError(t, err)

	testCases := []struct {
		name           string
		helmOption     *helm.Options
		resultFileName string
	}{
		{
			name:           "TestAllComponentsEnabled",
			resultFileName: "storagecluster_all_compenents_enabled.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_all_components_enabled.yaml"},
			},
		},
		{
			name:           "TestDefaultChartValues",
			resultFileName: "storagecluster_with_default_values.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{"internalKVDB": "true"},
			},
		},
		{
			name:           "TestCustomRegistry",
			resultFileName: "storagecluster_custom_registry.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_custom_registry.yaml"},
			},
		},
		{
			name:           "TestExternalETCD",
			resultFileName: "storagecluster_external_etcd.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_external_etcd.yaml"},
			},
		},
		{
			name:           "TestPlacementTolerations",
			resultFileName: "storagecluster_placement.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_placement.yaml"},
			},
		},
		{
			name:           "TestUpdateStrategyRollingUpdate",
			resultFileName: "storagecluster_updatestrategy_rollingupdate.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_updatestrategy_rollingupdate.yaml"},
			},
		},
		{
			name:           "TestUpdateStrategyOndelete",
			resultFileName: "storagecluster_updatestrategy_ondelete.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"updateStrategy.type": "OnDelete",
					"internalKVDB":"true",
					"updateStrategy.autoUpdateComponents":"Once",
					"imageVersion": "3.0.5",
				},
			},
		},
		{
			name:           "TestUpdateStrategyWithInvalidType",
			resultFileName: "storagecluster_updatestrategy_invalid_type.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"updateStrategy.type": "Invalid",
					"internalKVDB":"true",
					"updateStrategy.autoUpdateComponents":"None",
					"imageVersion": "3.0.5",
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
			test_utils.TestRenderedHelmTemplate(t, testCase.helmOption, helmChartPath, templateFileName, resultFilePath)
		})
	}
}
