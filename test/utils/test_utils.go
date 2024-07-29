package test_utils

import (
	"fmt"
	"os"
	"reflect"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/gruntwork-io/terratest/modules/helm"
	log "github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
)

func TestRenderedHelmTemplate(t *testing.T, helmOptions *helm.Options, helmChartPath string, renderTemplateFileName string, resultFilePath string) {
	t.Helper()

	resultFileContent, err := os.ReadFile(resultFilePath)
	if err != nil {
		log.Errorf("Error while reading result YAML file. %v", err)
		t.Fail()
	}

	var resultFileData interface{}
	helm.UnmarshalK8SYaml(t, string(resultFileContent), &resultFileData)

	output := helm.RenderTemplate(t, helmOptions, helmChartPath, "my-release", []string{fmt.Sprintf("templates/%v", renderTemplateFileName)})

	var storageCluster interface{}
	helm.UnmarshalK8SYaml(t, output, &storageCluster)

	require.Equal(t, isYamlMatched(resultFileData, storageCluster), true)
}

func isYamlMatched(expected, actual interface{}) bool {
	if !reflect.DeepEqual(expected, actual) {
		diff := cmp.Diff(expected, actual)
		fmt.Printf("Differences found:\n%v", diff)
		return false
	}
	return true
}
