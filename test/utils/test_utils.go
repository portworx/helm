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

func TestRenderedHelmTemplate(t *testing.T, helmOptions *helm.Options, helmChartPath string, renderTemplateFileName string, resultFilePath string, expectedErrorMsg string) {
	t.Helper()

	output, err := helm.RenderTemplateE(t, helmOptions, helmChartPath, "my-release", []string{fmt.Sprintf("templates/%v", renderTemplateFileName)})
	if err != nil {
		require.ErrorContains(t, err, expectedErrorMsg)
		return
	}

	resultFileContent, err := os.ReadFile(resultFilePath)
	if err != nil {
		log.Errorf("Error while reading result YAML file. %v", err)
		t.Fail()
	}

	var resultFileData interface{}
	helm.UnmarshalK8SYaml(t, string(resultFileContent), &resultFileData)

	var templateOutput interface{}
	helm.UnmarshalK8SYaml(t, output, &templateOutput)

	require.Equal(t, isYamlMatched(resultFileData, templateOutput), true)
}

func isYamlMatched(expected, actual interface{}) bool {
	// Remove specific chart annotation/label before comparison
	cleanExpected := removeDynamicFields(expected)
	cleanActual := removeDynamicFields(actual)

	if !reflect.DeepEqual(cleanExpected, cleanActual) {
		diff := cmp.Diff(cleanExpected, cleanActual)
		fmt.Printf("Differences found:\n%v", diff)
		return false
	}
	return true
}

// Helper function to remove "chart" label or annotation with dynamic value
func removeDynamicFields(obj interface{}) interface{} {
	switch obj := obj.(type) {
	case map[string]interface{}:
		// Check for metadata.annotations and remove the "chart" annotation
		if metadata, ok := obj["metadata"].(map[string]interface{}); ok {
			if annotations, ok := metadata["annotations"].(map[string]interface{}); ok {
				delete(annotations, "chart")
			}
		}
		// Check for labels and remove the "chart" label
		if labels, ok := obj["metadata"].(map[string]interface{}); ok {
			if labels, ok := labels["labels"].(map[string]interface{}); ok {
				delete(labels, "chart")
			}
		}
		// Remove "image" field if present
		delete(obj, "image")

		// Recursively clean nested fields
		for key, value := range obj {
			obj[key] = removeDynamicFields(value)
		}
	case []interface{}:
		// Recursively clean annotations in list items
		for i, value := range obj {
			obj[i] = removeDynamicFields(value)
		}
	}
	return obj
}
