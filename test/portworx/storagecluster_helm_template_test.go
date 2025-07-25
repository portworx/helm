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
		name             string
		helmOption       *helm.Options
		resultFileName   string
		expectedErrorMsg string
	}{
		{
			name:             "Failed: NoEtcdConfigurationProvided",
			expectedErrorMsg: "A valid ETCD url in the format etcd:http://<your-etcd-endpoint> is required.",
			helmOption: &helm.Options{SetValues: map[string]string{
				"internalKVDB": "false",
			}},
		},
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
					"csi.enabled":                   "true",
					"csi.installSnapshotController": "true",
				},
			},
		},
		{
			name:           "TestCSIDisabled",
			resultFileName: "storagecluster_csi_disabled.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"csi.enabled":                   "false",
					"csi.installSnapshotController": "true",
					"csi.topology.enabled":          "true",
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
					"monitoring.prometheus.enabled":       "false",
					"monitoring.prometheus.exportMetrics": "true",
					"monitoring.telemetry":                "false",
				},
			},
		},
		{
			name:           "TestMonitoringConditionByDisablingAllComponents",
			resultFileName: "storagecluster_monitoring_disable_by_all_components_disabled.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"monitoring.prometheus.enabled":       "false",
					"monitoring.prometheus.exportMetrics": "false",
					"monitoring.telemetry":                "false",
				},
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
			name:           "TestUpdateStrategyRollingSmartUpdate",
			resultFileName: "storagecluster_updatestrategy_rollingupdate_smart.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_updatestrategy_rollingupdate_smart.yaml"},
			},
		},
		{
			name:           "TestUpdateStrategyRollingDisruptionNotSet",
			resultFileName: "storagecluster_updatestrategy_rollingupdate_disruption_not_set.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_updatestrategy_rollingupdate_disruption_not_set.yaml"},
			},
		},
		{
			name:           "TestUpdateStrategyOndelete",
			resultFileName: "storagecluster_updatestrategy_ondelete.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"updateStrategy.type":                 "OnDelete",
					"updateStrategy.autoUpdateComponents": "Once",
				},
			},
		},
		{
			name:           "TestUpdateStrategyWithInvalidType",
			resultFileName: "storagecluster_updatestrategy_invalid_type.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"updateStrategy.type":                 "Invalid",
					"updateStrategy.autoUpdateComponents": "None",
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
		{
			name:           "TestAutoPilot",
			resultFileName: "storagecluster_autopilot.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_autopilot.yaml"},
			},
		},
		{
			name:           "TestCloudStorage",
			resultFileName: "storagecluster_cloudstorage.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_cloudstorage.yaml"},
			},
		},
		{
			name:           "TestCloudStorageAKS",
			resultFileName: "storagecluster_cloudstorage_aks.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_cloudstorage_aks.yaml"},
			},
		},
		{
			name:           "TestStorageSpecDevices",
			resultFileName: "storagecluster_storage_devices.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_storage_devices.yaml"},
			},
		},
		{
			name:           "TestStorageSpecWithUseAll",
			resultFileName: "storagecluster_storage_use_all.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_storage_use_all.yaml"},
			},
		},
		{
			name:           "TestStorageSpecWithUseAll",
			resultFileName: "storagecluster_storage_use_all.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_storage_use_partitions.yaml"},
			},
		},
		{
			name:           "TestStorageSpecWithUsePartitions",
			resultFileName: "storagecluster_storage_use_partitions.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_storage_use_partitions.yaml"},
			},
		},
		{
			name:           "TestNonDisruptiveUpgradeAndHealthChecksAnnotation",
			resultFileName: "storagecluster_non_disruptive_and_health_cheks_annotation.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"nonDisruptivek8sUpgrade": "true",
					"skipHealthChecks":        "true",
				},
			},
		},
		{
			name:           "TestInternalKvdbTlsEnabled",
			resultFileName: "storagecluster_internal_kvdb_tls_enabled.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"internalKVDB":    "true",
					"internalKvdbTls": "true",
				},
			},
		},
		{
			name:           "TestCertManagerEnabled",
			resultFileName: "storagecluster_cert_manager_enabled.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"internalKVDB":       "true",
					"installCertManager": "true",
				},
			},
		},
		{
			name:           "TestInternalKvdbTlsAndCertManagerEnabled",
			resultFileName: "storagecluster_internal_kvdb_tls_and_cert_manager.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"internalKVDB":       "true",
					"internalKvdbTls":    "true",
					"installCertManager": "true",
				},
			},
		},
		{
			name:           "TestInternalKvdbTlsAndCertManagerDisabled",
			resultFileName: "storagecluster_internal_kvdb_tls_and_cert_manager_disabled.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"internalKVDB":       "true",
					"internalKvdbTls":    "false",
					"installCertManager": "false",
				},
			},
		},
		{
			name:           "TestMigrateToKvdbTlsEnabled",
			resultFileName: "storagecluster_migrate_to_kvdb_tls_enabled.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"internalKVDB":     "true",
					"internalKvdbTls":  "true",
					"migrateToKvdbTls": "true",
				},
			},
		},
		{
			name:             "TestMigrateToKvdbTlsWithoutInternalKvdbTls",
			expectedErrorMsg: "migrateToKvdbTls requires internalKvdbTls to be enabled. Please set internalKvdbTls to true.",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"internalKVDB":     "true",
					"internalKvdbTls":  "false",
					"migrateToKvdbTls": "true",
				},
			},
		},
		{
			name:           "TestInstanceVolumeK8sUpgrade",
			resultFileName: "storagecluster_instance_volume_k8s_upgrade.yaml",
			helmOption: &helm.Options{
				SetValues: map[string]string{
					"instanceVolumeK8sUpgrade": "true",
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
