# Kubectl Image Builder for Airgapped Environments

This directory contains the Dockerfile and Makefile for building kubectl images for Portworx deployments in airgapped environments.

## How to Get This Makefile

The Makefile is packaged with the Portworx Helm chart. When you pull the chart, you automatically get the build tools:

```bash
# Pull the chart
helm pull portworx/portworx --untar

# The Makefile is located at:
# portworx/docker/kubectl/Makefile
```

## Overview

Portworx Helm chart requires kubectl for lifecycle hooks. This solution provides two deployment modes:

### 1. **Non-Airgapped Mode** (Default)
- Uses `portworx/kubectl:non-airgapped` image
- Downloads the correct kubectl version at **runtime** based on the Kubernetes cluster version
- No need to rebuild images for different K8s versions
- Requires internet access during pod initialization

### 2. **Airgapped Mode**
- Uses `portworx/kubectl:airgapped` image
- kubectl binary is **pre-installed** at build time
- No internet access required during runtime
- Must rebuild image when Kubernetes version changes

## Why This Solution?

Previously, the chart depended on external images like `bitnami/kubectl` or `alpine/kubectl`, which:
- ❌ Lag behind new Kubernetes releases
- ❌ May not have the exact version you need
- ❌ Are outside your control

This solution:
- ✅ Removes dependency on third-party images
- ✅ Works with any Kubernetes version
- ✅ Supports both connected and airgapped environments
- ✅ Uses fixed, predictable image tags

## Quick Start

### For Airgapped Environments

```bash
# Step 1: Pull the Helm chart (on internet-connected machine)
helm pull portworx/portworx --untar

# Step 2: Build and push the kubectl image
cd portworx/docker/kubectl
make build-airgapped KUBECTL_VERSION=1.34.4 DOCKER_HUB_REPO=registry.company.com/portworx

# Step 3: Deploy Portworx (in airgapped environment)
helm install portworx ./portworx -n portworx \
  --set isAirgapped=true \
  --set customRegistryURL=registry.company.com/portworx
```

### For Non-Airgapped Environments

```bash
# Step 1: Build non-airgapped image (one-time)
cd charts/portworx/docker/kubectl
make build-non-airgapped DOCKER_HUB_REPO=docker.io/portworx

# Step 2: Deploy Portworx
helm install portworx ./charts/portworx -n portworx \
  --set isAirgapped=false \
  --set customRegistryURL=docker.io/portworx
```

## Makefile Targets

| Target | Description | Required Args |
|--------|-------------|---------------|
| `make build-airgapped` | Build airgapped image with pre-installed kubectl | `KUBECTL_VERSION` |
| `make build-non-airgapped` | Build non-airgapped image (runtime downloader) | None |
| `make help` | Display usage information | None |

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `KUBECTL_VERSION` | Yes (airgapped only) | - | Kubernetes version (e.g., 1.34.4) |
| `DOCKER_HUB_REPO` | No | docker.io/portworx | Registry URL |
| `PLATFORMS` | No | linux/amd64,linux/arm64 | Target platforms |

## Image Tags

| Mode | Image Tag | Example |
|------|-----------|---------|
| Non-Airgapped | `non-airgapped` | `portworx/kubectl:non-airgapped` |
| Airgapped | `airgapped` | `portworx/kubectl:airgapped` |

## Examples

```bash
# Build airgapped for K8s 1.34.4
make build-airgapped KUBECTL_VERSION=1.34.4 DOCKER_HUB_REPO=registry.company.com/portworx

# Build non-airgapped
make build-non-airgapped DOCKER_HUB_REPO=docker.io/portworx

# Build locally for testing
make build-airgapped-local KUBECTL_VERSION=1.34.4
```

## Complete Customer Workflow

### Scenario: Airgapped Kubernetes Cluster

**Note:** The build machine has internet access, but the Kubernetes cluster is in an airgapped environment.

```bash
# 1. Add Portworx Helm repository
helm repo add portworx https://raw.githubusercontent.com/portworx/helm/master/repo/stable

# 2. Update repository
helm repo update

# 3. Pull the Helm chart (includes Dockerfile and Makefile)
helm pull portworx/portworx --untar

# 4. Navigate to kubectl build directory
cd portworx/docker/kubectl

# 5. Login to your private registry (accessible from airgapped cluster)
docker login registry.company.com

# 6. Build and push kubectl image to your private registry
make build-airgapped KUBECTL_VERSION=1.34.4 DOCKER_HUB_REPO=registry.company.com/portworx

# 7. Deploy Portworx to airgapped cluster
cd ../../..
helm install portworx ./portworx -n portworx \
  --create-namespace \
  --set isAirgapped=true \
  --set customRegistryURL=registry.company.com/portworx

# 8. Verify deployment
kubectl get pods -n portworx
```

**What happens:**
- The kubectl image is pulled from your private registry (accessible from airgapped cluster)
- All other Portworx images should also be in your private registry
- No internet access is required from the Kubernetes cluster

## What Gets Packaged with Helm Chart

When customers do `helm pull portworx/portworx --untar`, they get:

```
portworx/
├── Chart.yaml
├── values.yaml
├── templates/
├── docker/
│   └── kubectl/
│       ├── Dockerfile          # Multi-stage build for both modes
│       ├── Makefile            # Build automation
│       └── README.md           # This documentation
└── ...
```

All build tools are included in the Helm chart package, so customers can build images offline after pulling the chart once.
