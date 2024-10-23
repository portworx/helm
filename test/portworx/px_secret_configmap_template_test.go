package portworx_test

import (
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	test_utils "github.com/portworx/helm/test/utils"
	"github.com/stretchr/testify/require"
)

func TestPxVsphereSecretHelmTemplate(t *testing.T) {

	t.Parallel()

	// Path to the helm chart we will test
	helmChartPath, err := filepath.Abs("../../charts/portworx/")
	// name of template that we want to test
	templateFileName := "px-vsphere-secret.yaml"
	require.NoError(t, err)

	testCases := []struct {
		name             string
		helmOption       *helm.Options
		resultFileName   string
		expectedErrorMsg string
	}{
		{
			name:           "TestVsphereSecret",
			resultFileName: "px_vsphere_secret.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_vsphere_cloudrive.yaml"},
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

func TestPxPureSecretHelmTemplate(t *testing.T) {

	t.Parallel()

	// Path to the helm chart we will test
	helmChartPath, err := filepath.Abs("../../charts/portworx/")
	// name of template that we want to test
	templateFileName := "px-pure-secret.yaml"
	require.NoError(t, err)

	testCases := []struct {
		name             string
		helmOption       *helm.Options
		resultFileName   string
		expectedErrorMsg string
	}{
		{
			name:           "TestPureSecret",
			resultFileName: "px_pure_secret.yaml",
			helmOption: &helm.Options{
				SetFiles: map[string]string{
					"provider.pure.pureJsonFileData": "./testValues/pure.json",
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

func TestPxVersionsConfigmapHelmTemplate(t *testing.T) {

	t.Parallel()

	// Path to the helm chart we will test
	helmChartPath, err := filepath.Abs("../../charts/portworx/")
	// name of template that we want to test
	templateFileName := "px-versions-configmap.yaml"
	require.NoError(t, err)

	testCases := []struct {
		name             string
		helmOption       *helm.Options
		resultFileName   string
		expectedErrorMsg string
	}{
		{
			name:           "TesPxVersionsConfigMap",
			resultFileName: "px_versions_secret.yaml",
			helmOption: &helm.Options{
				SetFiles: map[string]string{
					"AirGappedInstall.pxVersionsYamlFileData": "./testValues/versions.yaml",
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

func TestPxAzureConfigmapHelmTemplate(t *testing.T) {

	t.Parallel()

	// Path to the helm chart we will test
	helmChartPath, err := filepath.Abs("../../charts/portworx/")
	// name of template that we want to test
	templateFileName := "px-azure-secret.yaml"
	require.NoError(t, err)

	testCases := []struct {
		name             string
		helmOption       *helm.Options
		resultFileName   string
		expectedErrorMsg string
	}{
		{
			name:           "TestPxAzureSecret",
			resultFileName: "px_azure_secret.yaml",
			helmOption: &helm.Options{
				ValuesFiles: []string{"./testValues/storagecluster_cloudstorage_aks.yaml"},
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
