# Current Operator version
VERSION          := 0.2.9
TAG              := v$(VERSION)
REGISTRY         ?= quay.io
ORG              ?= rh-nfv-int
DEFAULT_CHANNEL  ?= alpha
CONTAINER_CLI    ?= podman
CLUSTER_CLI      ?= oc
OPERATOR_NAME    := testpmd-lb-operator
OPERATOR_SDK_VER := 1.7.2
KUSTOMIZE_VER    := 3.5.4

# Default bundle image tag
BUNDLE_IMG ?= $(REGISTRY)/$(ORG)/$(OPERATOR_NAME)-bundle:$(TAG)
# Options for 'bundle-build'
ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

# Image URL to use all building/pushing image targets
IMG ?= $(REGISTRY)/$(ORG)/$(OPERATOR_NAME):$(TAG)

all: operator-all bundle-all

# Operator build and push
operator-all: operator-build operator-push

# Bundle build and push
bundle-all: bundle-build bundle-push

# Run against the configured Kubernetes cluster in ~/.kube/config
run: ansible-operator
	$(ANSIBLE_OPERATOR) run

# Install CRDs into a cluster
install: kustomize
	$(KUSTOMIZE) build config/crd | ${CLUSTER_CLI} apply -f -

# Uninstall CRDs from a cluster
uninstall: kustomize
	$(KUSTOMIZE) build config/crd | ${CLUSTER_CLI} delete -f -

# Deploy controller in the configured Kubernetes cluster in ~/.kube/config
deploy: kustomize
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/default | ${CLUSTER_CLI} apply -f -

# Undeploy controller in the configured Kubernetes cluster in ~/.kube/config
undeploy: kustomize
	$(KUSTOMIZE) build config/default | ${CLUSTER_CLI} delete -f -

# Build the operator image
operator-build:
	BUILDAH_FORMAT=docker ${CONTAINER_CLI} build . -t ${IMG}

# Push the operator image
operator-push:
	${CONTAINER_CLI} push ${IMG}

PATH  := $(PATH):$(PWD)/bin
SHELL := env PATH=$(PATH) /bin/sh
OS    = $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH  = $(shell uname -m | sed 's/x86_64/amd64/')
OSOPER   = $(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/apple-darwin/' | sed 's/linux/linux-gnu/')
ARCHOPER = $(shell uname -m )

# Download kustomize locally if necessary in $(pwd)/bin
.PHONY: kustomize
KUSTOMIZE = $(shell pwd)/bin/kustomize
kustomize:
ifeq (,$(wildcard $(KUSTOMIZE)))
	@{ \
	set -e ;\
	mkdir -p $(dir $(KUSTOMIZE)) ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v$(KUSTOMIZE_VER)/kustomize_v$(KUSTOMIZE_VER)_$(OS)_$(ARCH).tar.gz | \
	tar xzf - -C bin/ ;\
	}
endif

# Installs operator-sdk if is not available in $(pwd)/bin
.PHONY: operator-sdk
OPERATOR_SDK = $(shell pwd)/bin/operator-sdk
operator-sdk:
ifeq (,$(wildcard $(OPERATOR_SDK)))
	@{ \
	set -e ;\
	mkdir -p $(dir $(OPERATOR_SDK)) ;\
	curl -sLo $(OPERATOR_SDK) https://github.com/operator-framework/operator-sdk/releases/download/v$(OPERATOR_SDK_VER)/operator-sdk_$(OS)_$(ARCH) ; \
	chmod u+x $(OPERATOR_SDK) ; \
	}
else
endif

# Download ansible-operator locally if necessary, preferring the $(pwd)/bin path over global if both exist.
.PHONY: ansible-operator
ANSIBLE_OPERATOR = $(shell pwd)/bin/ansible-operator
ansible-operator:
ifeq (,$(wildcard $(ANSIBLE_OPERATOR)))
ifeq (,$(shell which ansible-operator 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(ANSIBLE_OPERATOR)) ;\
	curl -sSLo $(ANSIBLE_OPERATOR) https://github.com/operator-framework/operator-sdk/releases/download/v1.3.0/ansible-operator_$(OS)_$(ARCH) ;\
	chmod +x $(ANSIBLE_OPERATOR) ;\
	}
else
ANSIBLE_OPERATOR = $(shell which ansible-operator)
endif
endif

# Generate bundle manifests and metadata, then validate generated files.
.PHONY: bundle
bundle: kustomize operator-sdk
	$(OPERATOR_SDK) generate kustomize manifests -q
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
	$(KUSTOMIZE) build config/manifests | $(OPERATOR_SDK) generate bundle -q --overwrite --version $(VERSION) $(BUNDLE_METADATA_OPTS)
	DIGEST=$$(skopeo inspect docker://$(IMG) | jq -r '.Digest') && sed -i -e 's/\(\s*image: .*\):v'$(VERSION)'/\1@'$${DIGEST}'/' bundle/manifests/$(OPERATOR_NAME).clusterserviceversion.yaml
	sed -i -e '/^# Copy.*/i LABEL com.redhat.openshift.versions="v4.6"\nLABEL com.redhat.delivery.backport=false\nLABEL com.redhat.delivery.operator.bundle=true' bundle.Dockerfile
	cat relatedImages.yaml >> bundle/manifests/$(OPERATOR_NAME).clusterserviceversion.yaml
	$(OPERATOR_SDK) bundle validate ./bundle

# Build the bundle image, using local bundle image name
.PHONY: bundle-build
bundle-build: bundle
	BUILDAH_FORMAT=docker ${CONTAINER_CLI} build -f bundle.Dockerfile \
		-t bundle .

# Tag local bundle image with our registry BUNDLE_IMG
bundle-tag:
	${CONTAINER_CLI} tag bundle $(BUNDLE_IMG)

# Push the BUNDLE_IMG
bundle-push: bundle-tag
	${CONTAINER_CLI} push $(BUNDLE_IMG)
