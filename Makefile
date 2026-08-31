.PHONY: build

CHART ?=
CHART_REPO_URL ?= https://raw.githubusercontent.com/portworx/helm/master/stable

build:
ifeq ($(strip $(CHART)),)
	$(error CHART is required, e.g. make build CHART=px-observability-ui)
endif
	helm lint charts/$(CHART)
	helm package charts/$(CHART) -d stable/
	helm repo index stable/ --url $(CHART_REPO_URL) --merge stable/index.yaml
