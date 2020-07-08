OC_TOOL ?= "oc"
IMAGE_BUILD_CMD ?= "docker"
IMAGE_REGISTRY ?= "quay.io"
REGISTRY_NAMESPACE ?= "example-cnf"
IMAGE_TAG ?= "latest"

TARGET_GOOS=linux
TARGET_GOARCH=amd64

CACHE_DIR="_cache"
TOOLS_DIR="$(CACHE_DIR)/tools"

OPERATOR_SDK_VERSION="v0.18.0"
OPERATOR_SDK_PLATFORM ?= "x86_64-linux-gnu"
OPERATOR_SDK_BIN="operator-sdk-$(OPERATOR_SDK_VERSION)-$(OPERATOR_SDK_PLATFORM)"
OPERATOR_SDK="$(TOOLS_DIR)/$(OPERATOR_SDK_BIN)"

OPERATOR_IMAGE_NAME="testpmd-opeator"
# Separate repository
APPLICATION_IMAGE_NAME="testpmd-container-app"

FULL_OPERATOR_IMAGE ?= "$(IMAGE_REGISTRY)/$(REGISTRY_NAMESPACE)/$(OPERATOR_IMAGE_NAME):$(IMAGE_TAG)"
FULL_APPLICATION_IMAGE ?= "${IMAGE_REGISTRY}/${REGISTRY_NAMESPACE}/${APPLICATION_IMAGE_NAME}:${IMAGE_TAG}"

GIT_VERSION=$$(git describe --always --tags)
VERSION=$${CI_UPSTREAM_VERSION:-$(GIT_VERSION)}
GIT_COMMIT=$$(git rev-list -1 HEAD)
COMMIT=$${CI_UPSTREAM_COMMIT:-$(GIT_COMMIT)}
BUILD_DATE=$$(date --utc -Iseconds)

# Export GO111MODULE=on to enable project to be built from within GOPATH/src
export GO111MODULE=on

.PHONY: build
build:
	@echo "Building operator image"
	$(OPERATOR_SDK) build $(FULL_OPERATOR_IMAGE)

.PHONY: push
push: build
	@echo "Pushing opeator image"
	$(IMAGE_BUILD_CMD) push $(FULL_OPERATOR_IMAGE)

.PHONY: operator-sdk
operator-sdk:
	@if [ ! -x "$(OPERATOR_SDK)" ]; then\
		echo "Downloading operator-sdk $(OPERATOR_SDK_VERSION)";\
		mkdir -p $(TOOLS_DIR);\
		curl -JL https://github.com/operator-framework/operator-sdk/releases/download/$(OPERATOR_SDK_VERSION)/$(OPERATOR_SDK_BIN) -o $(OPERATOR_SDK);\
		chmod +x $(OPERATOR_SDK);\
	else\
		echo "Using operator-sdk cached at $(OPERATOR_SDK)";\
	fi

.PHONY: cluster-deploy
cluster-deploy:
	@echo "Deploying operator"
	${OC_TOOL} kustomize | envsubst | ${OC_TOOL} apply -f - 

.PHONY: cluster-clean
cluster-clean:
	@echo "Deleting operator"
	${OC_TOOL} delete namespace example-cnf

