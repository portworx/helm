# Dockerfile for kubectl images
# Supports two modes:
# 1. Non-airgapped (BUILD_MODE=non-airgapped): Downloads kubectl at runtime based on K8s version
# 2. Airgapped (BUILD_MODE=airgapped): Pre-installs kubectl at build time

ARG BUILD_MODE=airgapped

# Stage 1: Airgapped mode - Pre-install kubectl at build time
FROM alpine:3.19 AS airgapped-builder

RUN apk add --no-cache \
    curl \
    ca-certificates \
    bash

ARG KUBECTL_VERSION=v1.30.0

# Download kubectl binary at build time
RUN echo "Downloading kubectl ${KUBECTL_VERSION} for airgapped mode..." && \
    ARCH=$(uname -m) && \
    case $ARCH in \
        x86_64) ARCH="amd64" ;; \
        aarch64) ARCH="arm64" ;; \
        armv7l) ARCH="arm" ;; \
    esac && \
    curl -fL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" \
        -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    echo "kubectl ${KUBECTL_VERSION} installed successfully"


RUN kubectl version --client

# Stage 2: Non-airgapped mode - Runtime kubectl downloader
FROM alpine:3.19 AS non-airgapped-builder

RUN apk add --no-cache \
    curl \
    ca-certificates \
    bash

# Create kubectl wrapper script that downloads kubectl at runtime
RUN cat > /usr/local/bin/kubectl-wrapper.sh << 'EOF'
#!/bin/bash
set -e

KUBECTL_BIN="/usr/local/bin/kubectl-binary"

# Check if kubectl is already downloaded
if [ ! -f "$KUBECTL_BIN" ]; then
    # Detect Kubernetes version from environment or use default
    KUBECTL_VERSION="${KUBECTL_VERSION:-v1.30.0}"

    if [[ ! "$KUBECTL_VERSION" =~ ^v ]]; then
        KUBECTL_VERSION="v${KUBECTL_VERSION}"
    fi

    echo "Downloading kubectl ${KUBECTL_VERSION}..."

    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l) ARCH="arm" ;;
    esac

    # Download kubectl
    curl -fL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" \
        -o "$KUBECTL_BIN"
    chmod +x "$KUBECTL_BIN"

    echo "kubectl ${KUBECTL_VERSION} downloaded successfully"
fi

# Execute kubectl with all arguments
exec "$KUBECTL_BIN" "$@"
EOF

RUN chmod +x /usr/local/bin/kubectl-wrapper.sh

# Final stage: Choose based on BUILD_MODE
FROM alpine:3.19

# Install minimal runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    bash \
    curl

ARG BUILD_MODE=airgapped

# Copy appropriate files based on build mode
COPY --from=airgapped-builder /usr/local/bin/kubectl /tmp/kubectl-airgapped
COPY --from=non-airgapped-builder /usr/local/bin/kubectl-wrapper.sh /tmp/kubectl-wrapper.sh

# Install the appropriate kubectl based on BUILD_MODE
RUN if [ "$BUILD_MODE" = "airgapped" ]; then \
        echo "Installing airgapped kubectl..."; \
        cp /tmp/kubectl-airgapped /usr/local/bin/kubectl; \
        rm /tmp/kubectl-wrapper.sh; \
    else \
        echo "Installing non-airgapped kubectl wrapper..."; \
        cp /tmp/kubectl-wrapper.sh /usr/local/bin/kubectl; \
        rm /tmp/kubectl-airgapped; \
    fi && \
    chmod +x /usr/local/bin/kubectl && \
    rm -f /tmp/kubectl-*

# Set working directory
WORKDIR /root

# Use kubectl as entrypoint
ENTRYPOINT ["kubectl"]
CMD ["version", "--client"]

