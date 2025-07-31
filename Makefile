# Makefile for building and pushing Docker images for the microservices

# ==============================================================================
# Variables
# ==============================================================================

# IMPORTANT: Change this to your Docker Hub username or container registry URL
DOCKER_USERNAME ?= qcodelabsllc

# Service names
SERVICE_A_NAME := service-a
SERVICE_B_NAME := service-b
SERVICE_C_NAME := service-c
SERVICE_D_NAME := service-d

# Image tags
IMAGE_TAG ?= latest
SERVICE_A_IMAGE := $(DOCKER_USERNAME)/$(SERVICE_A_NAME):$(IMAGE_TAG)
SERVICE_B_IMAGE := $(DOCKER_USERNAME)/$(SERVICE_B_NAME):$(IMAGE_TAG)
SERVICE_C_IMAGE := $(DOCKER_USERNAME)/$(SERVICE_C_NAME):$(IMAGE_TAG)
SERVICE_D_IMAGE := $(DOCKER_USERNAME)/$(SERVICE_D_NAME):$(IMAGE_TAG)


# ==============================================================================
# Targets
# ==============================================================================

.PHONY: all build push clean build-a build-b push-a push-b

# Default target: builds and pushes all services
all: build push

# Build all service images
build: build-a build-b build-c build-d

# Push all service images
push: push-a push-b push-c push-d

# Build the Docker image for Service A
build-a:
	@echo "Building Docker image for $(SERVICE_A_NAME)..."
	@docker build --platform=linux/amd64 -t $(SERVICE_A_IMAGE) ./svc-a
	@echo "Successfully built $(SERVICE_A_IMAGE)"

# Build the Docker image for Service B
build-b:
	@echo "Building Docker image for $(SERVICE_B_NAME)..."
	@docker build --platform=linux/amd64 -t $(SERVICE_B_IMAGE) ./svc-b
	@echo "Successfully built $(SERVICE_B_IMAGE)"

# Build the Docker image for Service C
build-c:
	@echo "Building Docker image for $(SERVICE_C_NAME)..."
	@docker build --platform=linux/amd64 -t $(SERVICE_C_IMAGE) ./svc-b
	@echo "Successfully built $(SERVICE_C_IMAGE)"

# Build the Docker image for Service D
build-d:
	@echo "Building Docker image for $(SERVICE_D_IMAGE)..."
	@docker build --platform=linux/amd64 -t $(SERVICE_D_IMAGE) ./svc-b
	@echo "Successfully built $(SERVICE_D_IMAGE)"

# Push the Docker image for Service A to the registry
push-a:
	@echo "Pushing $(SERVICE_A_IMAGE) to the registry..."
	@docker push $(SERVICE_A_IMAGE)
	@echo "Successfully pushed $(SERVICE_A_IMAGE)"

# Push the Docker image for Service B to the registry
push-b:
	@echo "Pushing $(SERVICE_B_IMAGE) to the registry..."
	@docker push $(SERVICE_B_IMAGE)
	@echo "Successfully pushed $(SERVICE_B_IMAGE)"

# Push the Docker image for Service C to the registry
push-c:
	@echo "Pushing $(SERVICE_C_IMAGE) to the registry..."
	@docker push $(SERVICE_C_IMAGE)
	@echo "Successfully pushed $(SERVICE_C_IMAGE)"

# Push the Docker image for Service D to the registry
push-d:
	@echo "Pushing $(SERVICE_D_IMAGE) to the registry..."
	@docker push $(SERVICE_D_IMAGE)
	@echo "Successfully pushed $(SERVICE_D_IMAGE)"

# Clean up Docker images (optional)
clean:
	@echo "Removing local Docker images..."
	@docker rmi $(SERVICE_A_IMAGE) || true
	@docker rmi $(SERVICE_B_IMAGE) || true
	@docker rmi $(SERVICE_C_IMAGE) || true
	@docker rmi $(SERVICE_D_IMAGE) || true
	@echo "Cleanup complete."