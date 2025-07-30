# Makefile for building and pushing Docker images for the microservices

# ==============================================================================
# Variables
# ==============================================================================

# IMPORTANT: Change this to your Docker Hub username or container registry URL
DOCKER_USERNAME ?= qcodelabsllc

# Service names
SERVICE_A_NAME := service-a
SERVICE_B_NAME := service-b

# Image tags
IMAGE_TAG ?= latest
SERVICE_A_IMAGE := $(DOCKER_USERNAME)/$(SERVICE_A_NAME):$(IMAGE_TAG)
SERVICE_B_IMAGE := $(DOCKER_USERNAME)/$(SERVICE_B_NAME):$(IMAGE_TAG)


# ==============================================================================
# Targets
# ==============================================================================

.PHONY: all build push clean build-a build-b push-a push-b

# Default target: builds and pushes all services
all: build push

# Build all service images
build: build-a build-b

# Push all service images
push: push-a push-b

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

# Clean up Docker images (optional)
clean:
	@echo "Removing local Docker images..."
	@docker rmi $(SERVICE_A_IMAGE) || true
	@docker rmi $(SERVICE_B_IMAGE) || true
	@echo "Cleanup complete."

# List available commands
help:
	@echo "Available commands:"
	@echo "  make build         - Build Docker images for all services"
	@echo "  make push          - Push Docker images for all services to the registry"
	@echo "  make all           - Build and push all images"
	@echo "  make build-a       - Build the image for service-a"
	@echo "  make push-a        - Push the image for service-a"
	@echo "  make build-b       - Build the image for service-b"
	@echo "  make push-b        - Push the image for service-b"
	@echo "  make clean         - Remove the built Docker images locally"
	@echo ""
	@echo "You can override the Docker username and tag like this:"
	@echo "  make DOCKER_USERNAME=myuser IMAGE_TAG=v1.1 all"