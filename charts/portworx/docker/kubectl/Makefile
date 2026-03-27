# Makefile for building and pushing kubectl images
#
# Two modes:
#   1. Non-airgapped: Runtime kubectl downloader (tag: non-airgapped)
#   2. Airgapped: Pre-built kubectl image (tag: airgapped)
#
# Usage:
#   # For non-airgapped (runtime download)
#   make build-non-airgapped DOCKER_HUB_REPO=docker.io/portworx
#
#   # For airgapped (pre-built)
#   make build-airgapped KUBECTL_VERSION=1.34.4 DOCKER_HUB_REPO=registry.company.com/portworx
#
# Environment Variables:
#   KUBECTL_VERSION                 - Kubernetes version (required for airgapped, e.g., 1.34.4)
#   DOCKER_HUB_REPO                 - Registry URL (default: docker.io/portworx)
#   DOCKER_HUB_KUBECTL_IMG          - Image name (default: kubectl, fixed)
#   PLATFORMS                       - Target platforms (default: linux/amd64,linux/arm64)

# Default values with warnings
ifndef DOCKER_HUB_REPO
    DOCKER_HUB_REPO := docker.io/portworx
    $(warning DOCKER_HUB_REPO not defined, using '$(DOCKER_HUB_REPO)' instead)
endif

ifndef DOCKER_HUB_KUBECTL_IMG
    DOCKER_HUB_KUBECTL_IMG := kubectl
    $(warning DOCKER_HUB_KUBECTL_IMG not defined, using '$(DOCKER_HUB_KUBECTL_IMG)' instead)
endif

# Platforms for multi-arch build
ifndef PLATFORMS
    PLATFORMS := linux/amd64,linux/arm64
endif

# Image names for different modes
NON_AIRGAPPED_TAG := non-airgapped
AIRGAPPED_TAG := airgapped

NON_AIRGAPPED_IMAGE := $(DOCKER_HUB_REPO)/$(DOCKER_HUB_KUBECTL_IMG):$(NON_AIRGAPPED_TAG)
AIRGAPPED_IMAGE := $(DOCKER_HUB_REPO)/$(DOCKER_HUB_KUBECTL_IMG):$(AIRGAPPED_TAG)

# For airgapped mode, normalize kubectl version
# Accept version without 'v' prefix (e.g., 1.33.4) and add 'v' prefix for kubectl download
ifdef KUBECTL_VERSION
    KUBECTL_VERSION_NORMALIZED := $(KUBECTL_VERSION)
    # Strip 'v' prefix if present
    KUBECTL_VERSION_NORMALIZED := $(patsubst v%,%,$(KUBECTL_VERSION_NORMALIZED))
    # Add 'v' prefix for kubectl download URL
    KUBECTL_VERSION_NORMALIZED := v$(KUBECTL_VERSION_NORMALIZED)
else
    KUBECTL_VERSION_NORMALIZED := v1.30.0
endif

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: help
help:
	@echo "$(GREEN)Kubectl Image Builder$(NC)"
	@echo ""
	@echo "$(BLUE)Two Build Modes:$(NC)"
	@echo "  1. Non-airgapped: Downloads kubectl at runtime (no K8s version needed)"
	@echo "  2. Airgapped:     Pre-built kubectl image (requires K8s version)"
	@echo ""
	@echo "$(BLUE)Usage:$(NC)"
	@echo "  # Non-airgapped mode (runtime download)"
	@echo "  make build-non-airgapped [DOCKER_HUB_REPO=<registry>]"
	@echo ""
	@echo "  # Airgapped mode (pre-built)"
	@echo "  make build-airgapped KUBECTL_VERSION=<k8s-version> [DOCKER_HUB_REPO=<registry>]"
	@echo ""
	@echo "$(BLUE)Environment Variables:$(NC)"
	@echo "  KUBECTL_VERSION  - Kubernetes version (required for airgapped, e.g., 1.34.4)"
	@echo "  DOCKER_HUB_REPO  - Registry URL (default: docker.io/portworx)"
	@echo "  PLATFORMS        - Target platforms (default: linux/amd64,linux/arm64)"
	@echo ""
	@echo "$(BLUE)Examples:$(NC)"
	@echo "  # Build non-airgapped image"
	@echo "  make build-non-airgapped DOCKER_HUB_REPO=docker.io/portworx"
	@echo ""
	@echo "  # Build airgapped image for K8s 1.34.4"
	@echo "  make build-airgapped KUBECTL_VERSION=1.34.4 DOCKER_HUB_REPO=registry.company.com/portworx"
	@echo ""
	@echo "$(BLUE)Image Tags:$(NC)"
	@echo "  Non-airgapped: <DOCKER_HUB_REPO>/kubectl:non-airgapped"
	@echo "  Airgapped:     <DOCKER_HUB_REPO>/kubectl:airgapped"

.PHONY: info-non-airgapped
info-non-airgapped:
	@echo "$(GREEN)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║  Non-Airgapped Kubectl Image Configuration                ║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "  Mode:                Non-airgapped (runtime download)"
	@echo "  Registry:            $(DOCKER_HUB_REPO)"
	@echo "  Image Name:          $(DOCKER_HUB_KUBECTL_IMG)"
	@echo "  Image Tag:           $(NON_AIRGAPPED_TAG)"
	@echo "  Full Image:          $(NON_AIRGAPPED_IMAGE)"
	@echo "  Platforms:           $(PLATFORMS)"
	@echo "  Kubectl Download:    At runtime based on KUBECTL_VERSION env variable"
	@echo ""

.PHONY: info-airgapped
info-airgapped:
	@echo "$(GREEN)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║  Airgapped Kubectl Image Configuration                    ║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "  Mode:                Airgapped (pre-built)"
	@echo "  Kubernetes Version:  $(KUBECTL_VERSION_NORMALIZED)"
	@echo "  Registry:            $(DOCKER_HUB_REPO)"
	@echo "  Image Name:          $(DOCKER_HUB_KUBECTL_IMG)"
	@echo "  Image Tag:           $(AIRGAPPED_TAG)"
	@echo "  Full Image:          $(AIRGAPPED_IMAGE)"
	@echo "  Platforms:           $(PLATFORMS)"
	@echo "  Kubectl Version:     Pre-installed $(KUBECTL_VERSION_NORMALIZED)"
	@echo ""

.PHONY: check-buildx
check-buildx:
	@echo "$(BLUE)ℹ Checking prerequisites...$(NC)"
	@which docker > /dev/null 2>&1 || { echo "$(RED)✗ Docker is not installed$(NC)"; exit 1; }
	@echo "$(GREEN)✓ Docker found$(NC)"
	@docker buildx version > /dev/null 2>&1 || { echo "$(RED)✗ Docker buildx is not available$(NC)"; exit 1; }
	@echo "$(GREEN)✓ Docker buildx found$(NC)"

.PHONY: create-builder
create-builder: check-buildx
	@if ! docker buildx inspect portworx-builder &> /dev/null 2>&1; then \
		echo "$(BLUE)ℹ Creating buildx builder 'portworx-builder'...$(NC)"; \
		docker buildx create --name portworx-builder --use; \
		echo "$(GREEN)✓ Builder created$(NC)"; \
	else \
		docker buildx use portworx-builder; \
		echo "$(GREEN)✓ Using existing builder$(NC)"; \
	fi

.PHONY: check-kubectl-version
check-kubectl-version:
ifndef KUBECTL_VERSION
	$(error KUBECTL_VERSION is required for airgapped build. Usage: make build-airgapped KUBECTL_VERSION=1.34.4)
endif

.PHONY: build-non-airgapped
build-non-airgapped: info-non-airgapped create-builder
	@echo ""
	@echo "$(BLUE)ℹ Building non-airgapped kubectl image (runtime downloader)...$(NC)"
	@echo ""
	docker buildx build \
		--platform $(PLATFORMS) \
		--build-arg BUILD_MODE=non-airgapped \
		-t $(NON_AIRGAPPED_IMAGE) \
		--push \
		.
	@echo ""
	@echo "$(GREEN)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║  Non-Airgapped Build Complete!                             ║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)✓ Image pushed to registry: $(NON_AIRGAPPED_IMAGE)$(NC)"
	@echo ""
	@echo "$(BLUE)This image downloads kubectl at runtime based on KUBECTL_VERSION env variable.$(NC)"
	@echo ""
	@echo "$(BLUE)Next steps:$(NC)"
	@echo "  1. Update your Helm values.yaml:"
	@echo ""
	@echo "     isAirgapped: false"
	@echo "     customRegistryURL: $(DOCKER_HUB_REPO)"
	@echo ""
	@echo "  2. Deploy Portworx:"
	@echo ""
	@echo "     helm install my-release ./charts/portworx -n portworx \\"
	@echo "       --set isAirgapped=false \\"
	@echo "       --set customRegistryURL=$(DOCKER_HUB_REPO)"
	@echo ""

.PHONY: build-airgapped
build-airgapped: check-kubectl-version info-airgapped create-builder
	@echo ""
	@echo "$(BLUE)ℹ Building airgapped kubectl image with pre-installed kubectl $(KUBECTL_VERSION_NORMALIZED)...$(NC)"
	@echo ""
	docker buildx build \
		--platform $(PLATFORMS) \
		--build-arg BUILD_MODE=airgapped \
		--build-arg KUBECTL_VERSION=$(KUBECTL_VERSION_NORMALIZED) \
		-t $(AIRGAPPED_IMAGE) \
		--push \
		.
	@echo ""
	@echo "$(GREEN)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║  Airgapped Build Complete!                                 ║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)✓ Image pushed to registry: $(AIRGAPPED_IMAGE)$(NC)"
	@echo ""
	@echo "$(BLUE)This image has kubectl $(KUBECTL_VERSION_NORMALIZED) pre-installed.$(NC)"
	@echo ""
	@echo "$(BLUE)Next steps:$(NC)"
	@echo "  1. Update your Helm values.yaml:"
	@echo ""
	@echo "     isAirgapped: true"
	@echo "     customRegistryURL: $(DOCKER_HUB_REPO)"
	@echo ""
	@echo "  2. Deploy Portworx:"
	@echo ""
	@echo "     helm install my-release ./charts/portworx -n portworx \\"
	@echo "       --set isAirgapped=true \\"
	@echo "       --set customRegistryURL=$(DOCKER_HUB_REPO)"
	@echo ""

.PHONY: build-non-airgapped-local
build-non-airgapped-local: info-non-airgapped check-buildx
	@echo ""
	@echo "$(BLUE)ℹ Building non-airgapped kubectl image locally...$(NC)"
	@echo ""
	docker buildx build \
		--platform linux/amd64 \
		--build-arg BUILD_MODE=non-airgapped \
		-t $(NON_AIRGAPPED_IMAGE) \
		--load \
		.
	@echo ""
	@echo "$(GREEN)✓ Image built locally: $(NON_AIRGAPPED_IMAGE)$(NC)"
	@echo ""
	@echo "$(BLUE)Test the image (will download kubectl at runtime):$(NC)"
	@echo "  docker run --rm -e KUBECTL_VERSION=1.34.4 $(NON_AIRGAPPED_IMAGE) version --client"
	@echo ""
	@echo "$(BLUE)Push to registry:$(NC)"
	@echo "  docker push $(NON_AIRGAPPED_IMAGE)"
	@echo ""

.PHONY: build-airgapped-local
build-airgapped-local: check-kubectl-version info-airgapped check-buildx
	@echo ""
	@echo "$(BLUE)ℹ Building airgapped kubectl image locally...$(NC)"
	@echo ""
	docker buildx build \
		--platform linux/amd64 \
		--build-arg BUILD_MODE=airgapped \
		--build-arg KUBECTL_VERSION=$(KUBECTL_VERSION_NORMALIZED) \
		-t $(AIRGAPPED_IMAGE) \
		--load \
		.
	@echo ""
	@echo "$(GREEN)✓ Image built locally: $(AIRGAPPED_IMAGE)$(NC)"
	@echo ""
	@echo "$(BLUE)Test the image:$(NC)"
	@echo "  docker run --rm $(AIRGAPPED_IMAGE) version --client"
	@echo ""
	@echo "$(BLUE)Push to registry:$(NC)"
	@echo "  docker push $(AIRGAPPED_IMAGE)"
	@echo ""

.DEFAULT_GOAL := help

