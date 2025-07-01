# Keycloak Docker Image Build
KEYCLOAK_TAG := docker.io/portworx/keycloak:26.2.4_v2
DOCKERFILE := keycloak.dockerfile

.PHONY: keycloak build-keycloak

# Build the keycloak Docker image
keycloak: build-keycloak

build-keycloak:
	docker build -f $(DOCKERFILE) -t $(KEYCLOAK_TAG) .
