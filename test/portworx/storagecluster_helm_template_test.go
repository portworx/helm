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
			name:           "TestCSITopologyEnabled",
			resultFileName: "storagecluster_csi_topology_enabled.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"internalKVDB":         "true",
					"csi.enabled":          "true",
					"csi.topology.enabled": "true",
				},
			},
		},
		{
			name:           "TestCSISnapshotControllerEnabled",
			resultFileName: "storagecluster_csi_Snapshot_Controller_enabled.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"internalKVDB":                  "true",
					"csi.enabled":                   "true",
					"csi.installSnapshotController": "true",
				},
			},
		},
		{
			name:           "TestMonitoringWithAllValues",
			resultFileName: "storagecluster_monitoring.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_monitoring.yaml"},
			},
		},
		{
			name:           "TestMonitoringWithExportMatrixEnabled",
			resultFileName: "storagecluster_monitoring_enabled_exportmatrix.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"internalKVDB":                        "true",
					"monitoring.prometheus.exportMetrics": "true",
				},
			},
		},
		{
			name:           "TestMonitoringConditionByEnablingTelemetry",
			resultFileName: "storagecluster_monitoring_enable_by_enable_telemetry.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{"monitoring.telemetry": "true", "internalKVDB": "true"},
			},
		},
		{
			name:           "TestStork",
			resultFileName: "storagecluster_stork.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_stork.yaml"},
			},
		},
		{
			name:           "TestVolumes",
			resultFileName: "storagecluster_volumes.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_volumes.yaml"},
			},
		},
		{
			name:           "TestPlacementNodeAffinity",
			resultFileName: "storagecluster_nodeAffinity.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_nodeAffinity.yaml"},
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
			name:           "TestRuntimeOptions",
			resultFileName: "storagecluster_runtimeOptions.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"runtimeOptions": "num_io_threads=10",
					"internalKVDB":   "true",
				},
			},
		},
		{
			name:           "TestFeatureGates",
			resultFileName: "storagecluster_featureGates.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"featureGates": "CSI=true",
					"internalKVDB": "true",
				},
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
					"updateStrategy.type":                 "OnDelete",
					"internalKVDB":                        "true",
					"updateStrategy.autoUpdateComponents": "Once",
					"imageVersion":                        "3.0.5",
				},
			},
		},
		{
			name:           "TestUpdateStrategyWithInvalidType",
			resultFileName: "storagecluster_updatestrategy_invalid_type.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"updateStrategy.type":                 "Invalid",
					"internalKVDB":                        "true",
					"updateStrategy.autoUpdateComponents": "None",
					"imageVersion":                        "3.0.5",
				},
			},
		},
		{
			name:           "TestSecurityEnabled",
			resultFileName: "storagecluster_security_enabled.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_security_enabled.yaml"},
			},
		},
		{
			name:           "TestSecurityDisabled",
			resultFileName: "storagecluster_with_default_values.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_security_disabled.yaml"},
			},
		},
		{
			name:           "TestPortworxContainerResources",
			resultFileName: "storagecluster_portworx_container_resources.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_portworx_container_resources.yaml"},
			},
		},
		{
			name:           "TestCustomMetadata",
			resultFileName: "storagecluster_custom_metadata.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_custom_metadata.yaml"},
			},
		},
		{
			name:           "TestNodesConfiguration",
			resultFileName: "storagecluster_nodes_configuration.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_nodes_configuration.yaml"},
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
