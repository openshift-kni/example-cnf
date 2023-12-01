SHELL            := /bin/bash
DATE             ?= $(shell date --utc +%Y%m%d%H%M)
SHA              ?= $(shell git rev-parse --short HEAD)
VERSION          := 0.2.11
TAG              := $(VERSION)-$(DATE).$(SHA)
REGISTRY         ?= quay.io
ORG              ?= rh-nfv-int
DEFAULT_CHANNEL  ?= alpha
CONTAINER_CLI    ?= podman
CLUSTER_CLI      ?= oc
OPERATOR_NAME    := cnf-app-mac-operator
OPERATOR_SDK_VER ?= 1.32.0
CONTROLLER_VER   := 0.4.1
KUSTOMIZE_VER    := 3.8.7
OS               = $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH             = $(shell uname -m | sed 's/x86_64/amd64/')

# CHANNELS define the bundle channels used in the bundle.
# Add a new line here if you would like to change its default config. (E.g CHANNELS = "preview,fast,stable")
# To re-generate a bundle for other specific channels without changing the standard setup, you can:
# - use the CHANNELS as arg of the bundle target (e.g make bundle CHANNELS=preview,fast,stable)
# - use environment variables to overwrite this value (e.g export CHANNELS="preview,fast,stable")
ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif

# DEFAULT_CHANNEL defines the default channel used in the bundle.
# Add a new line here if you would like to change its default config. (E.g DEFAULT_CHANNEL = "stable")
# To re-generate a bundle for any other default channel without changing the default setup, you can:
# - use the DEFAULT_CHANNEL as arg of the bundle target (e.g make bundle DEFAULT_CHANNEL=stable)
# - use environment variables to overwrite this value (e.g export DEFAULT_CHANNEL="stable")
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

# BUNDLE_IMG defines the image:tag used for the bundle.
# You can use it as an arg. (E.g make bundle-build BUNDLE_IMG=<some-registry>/<project-name-bundle>:<tag>)
BUNDLE_IMG ?= $(REGISTRY)/$(ORG)/$(OPERATOR_NAME)-bundle:v$(TAG)
REL_BUNDLE_IMG ?= $(REGISTRY)/$(ORG)/$(OPERATOR_NAME)-bundle:v$(VERSION)

# Image URL to use all building/pushing image targets
IMG ?= $(REGISTRY)/$(ORG)/$(OPERATOR_NAME):v$(TAG)
REL_IMG ?= $(REGISTRY)/$(ORG)/$(OPERATOR_NAME):v$(VERSION)
# Produce CRDs that work back to Kubernetes 1.11 (no version conversion)
CRD_OPTIONS ?= "crd:trivialVersions=true,preserveUnknownFields=false"

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

all: operator-all bundle-all

build-all: kustomize operator-build bundle-build

push-all: operator-push bundle-push

# Operator build and push
operator-all: operator-build operator-push

# Bundle build and push
bundle-all: bundle-build bundle-push

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

manifests: controller-gen ## Generate WebhookConfiguration, ClusterRole and CustomResourceDefinition objects.
	$(CONTROLLER_GEN) $(CRD_OPTIONS) rbac:roleName=manager-role webhook paths="./..." output:crd:artifacts:config=config/crd/bases

generate: controller-gen ## Generate code containing DeepCopy, DeepCopyInto, and DeepCopyObject method implementations.
	$(CONTROLLER_GEN) object:headerFile="hack/boilerplate.go.txt" paths="./..."

fmt: ## Run go fmt against code.
	go fmt ./...

vet: ## Run go vet against code.
	go vet ./...

ENVTEST_ASSETS_DIR=$(shell pwd)/testbin
test: manifests generate fmt vet ## Run tests.
	mkdir -p ${ENVTEST_ASSETS_DIR}
	test -f ${ENVTEST_ASSETS_DIR}/setup-envtest.sh || curl -sSLo ${ENVTEST_ASSETS_DIR}/setup-envtest.sh https://raw.githubusercontent.com/kubernetes-sigs/controller-runtime/v0.7.2/hack/setup-envtest.sh
	source ${ENVTEST_ASSETS_DIR}/setup-envtest.sh; fetch_envtest_tools $(ENVTEST_ASSETS_DIR); setup_envtest_env $(ENVTEST_ASSETS_DIR); go test ./... -coverprofile cover.out

##@ Build

build: generate fmt vet ## Build manager binary.
	go build -o bin/manager main.go

run: manifests generate fmt vet ## Run a controller from your host.
	go run ./main.go

docker-build: build ## Build docker image with the manager.
	if [ -n "$(RELEASE)" ]; then \
	${CONTAINER_CLI} build -t ${IMG} -t $(REL_IMG) . ;\
	${CONTAINER_CLI} push ${RELIMG} ;\
	else \
	${CONTAINER_CLI} build -t ${IMG} . --label quay.expires-after=2w ;\
	fi
	${CONTAINER_CLI} push ${IMG}

##@ Deployment

install: manifests kustomize ## Install CRDs into the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/crd | ${CLUSTER_CLI} apply -f -

uninstall: manifests kustomize ## Uninstall CRDs from the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/crd | ${CLUSTER_CLI} delete -f -

deploy: manifests kustomize ## Deploy controller to the K8s cluster specified in ~/.kube/config.
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/default | ${CLUSTER_CLI} apply -f -

undeploy: kustomize ## Undeploy controller from the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/default | ${CLUSTER_CLI} delete -f -

# Build the operator image
operator-build: kustomize
	if [ -n "$(RELEASE)" ]; then \
	BUILDAH_FORMAT=docker ${CONTAINER_CLI} build . -t ${IMG} -t $(REL_IMG); \
	else \
	BUILDAH_FORMAT=docker ${CONTAINER_CLI} build . --label quay.expires-after=2w -t ${IMG}; \
	fi
# Push the operator image
operator-push:
	${CONTAINER_CLI} push ${IMG}

CONTROLLER_GEN = $(shell pwd)/bin/controller-gen
controller-gen: ## Download controller-gen locally if necessary.
	$(call go-install-tool,$(CONTROLLER_GEN),sigs.k8s.io/controller-tools/cmd/controller-gen@v$(CONTROLLER_VER))

# Download kustomize locally if necessary, preferring the $(pwd)/bin path over global if both exist.
.PHONY: kustomize
KUSTOMIZE = $(shell pwd)/bin/kustomize
kustomize: bin/kustomize

bin/kustomize:
	mkdir -p bin && curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v$(KUSTOMIZE_VER)/kustomize_v$(KUSTOMIZE_VER)_$(OS)_$(ARCH).tar.gz | tar xzf - -C bin/

# Installs operator-sdk if is not available in $(pwd)/bin
.PHONY: operator-sdk
OPERATOR_SDK = $(shell pwd)/bin/operator-sdk
operator-sdk: bin/operator-sdk

bin/operator-sdk:
	mkdir -p $(dir $(OPERATOR_SDK)) && \
	curl -sLo $(OPERATOR_SDK) https://github.com/operator-framework/operator-sdk/releases/download/v$(OPERATOR_SDK_VER)/operator-sdk_$(OS)_$(ARCH) && \
	chmod u+x $(OPERATOR_SDK)

# go-install-tool will 'go install' any package $2 and install it to $1.
PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
define go-install-tool
@[ -f $(1) ] || { \
set -e ;\
GOBIN=$(PROJECT_DIR)/bin go install $(2) ;\
}
endef

# Generate bundle manifests and metadata, then validate generated files.
.PHONY: bundle
bundle: kustomize manifests operator-sdk
	$(OPERATOR_SDK) generate kustomize manifests -q
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
	$(KUSTOMIZE) build config/manifests | $(OPERATOR_SDK) generate bundle -q --overwrite --version $(TAG) $(BUNDLE_METADATA_OPTS)
	DIGEST=$$(skopeo inspect docker://$(IMG) | jq -r '.Digest') && sed -i -e 's/\(\s*image: .*\):v'$(TAG)'/\1@'$${DIGEST}'/' bundle/manifests/$(OPERATOR_NAME).clusterserviceversion.yaml
	$(OPERATOR_SDK) bundle validate ./bundle

# Build the bundle image, using local bundle image name
.PHONY: bundle-build
bundle-build: bundle
	if [ -n "$(RELEASE)" ]; then \
	BUILDAH_FORMAT=docker ${CONTAINER_CLI} build -f bundle.Dockerfile \
		-t bundle . ; \
	else \
	BUILDAH_FORMAT=docker ${CONTAINER_CLI} build -f bundle.Dockerfile --label quay.expires-after=2w \
		-t bundle . ; \
	fi

# Tag local bundle image with our registry BUNDLE_IMG
bundle-tag:
	${CONTAINER_CLI} tag bundle $(BUNDLE_IMG)
	if [ -n "$(RELEASE)" ]; then \
	${CONTAINER_CLI} tag bundle $(REL_BUNDLE_IMG); \
	fi

# Push the BUNDLE_IMG
bundle-push: bundle-tag
	${CONTAINER_CLI} push $(BUNDLE_IMG)
	if [ -n "$(RELEASE)" ]; then \
	${CONTAINER_CLI} push $(REL_BUNDLE_IMG); \
	fi

.PHONY: version # Display the version
version:
	@echo $(VERSION)
