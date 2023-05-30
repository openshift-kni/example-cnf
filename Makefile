# Current Operator version
VERSION ?= 0.2.5
REGISTRY ?= quay.io
ORG ?= rh-nfv-int
DEFAULT_CHANNEL ?= alpha

CONTAINER_CLI ?= podman
CLUSTER_CLI ?= oc

OPERATOR_NAME = testpmd-operator

# Default bundle image tag
BUNDLE_IMG ?= $(REGISTRY)/$(ORG)/$(OPERATOR_NAME)-bundle:v$(VERSION)
# Options for 'bundle-build'
ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

# Image URL to use all building/pushing image targets
IMG ?= $(REGISTRY)/$(ORG)/$(OPERATOR_NAME):v$(VERSION)

all: docker-build bundle-build

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
	${CLUSTER_CLI} apply -f config/manager/namespace.yaml
	$(KUSTOMIZE) build config/default | ${CLUSTER_CLI} apply -f -

# Undeploy controller in the configured Kubernetes cluster in ~/.kube/config
undeploy: kustomize
	$(KUSTOMIZE) build config/default | ${CLUSTER_CLI} delete -f -

# Build the docker image
docker-build:
	${CONTAINER_CLI} build . -t ${IMG}

PATH  := $(PATH):$(PWD)/bin
SHELL := env PATH=$(PATH) /bin/sh
OS    = $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH  = $(shell uname -m | sed 's/x86_64/amd64/')
OSOPER   = $(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/apple-darwin/' | sed 's/linux/linux-gnu/')
ARCHOPER = $(shell uname -m )

# Download kustomize locally if necessary, preferring the $(pwd)/bin path over global if both exist.
.PHONY: kustomize
KUSTOMIZE = $(shell pwd)/bin/kustomize
kustomize:
ifeq (,$(wildcard $(KUSTOMIZE)))
ifeq (,$(shell which kustomize 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(KUSTOMIZE)) ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v3.5.4/kustomize_v3.5.4_$(OS)_$(ARCH).tar.gz | \
	tar xzf - -C bin/ ;\
	}
else
KUSTOMIZE=$(shell which kustomize)
endif
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

# Push the docker image
docker-push-with-bundle:
	${CONTAINER_CLI} push ${IMG}

# Generate bundle manifests and metadata, then validate generated files.
.PHONY: bundle
bundle: kustomize docker-push-with-bundle
	operator-sdk generate kustomize manifests -q
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
	$(KUSTOMIZE) build config/manifests | operator-sdk generate bundle -q --overwrite --version $(VERSION) $(BUNDLE_METADATA_OPTS)
	$(eval DIGEST = $(shell skopeo inspect docker://$(IMG) | jq -r '.Digest'))
	sed -i -e 's/\(\s*image: .*\):v'$(VERSION)'/\1@'$(DIGEST)'/' bundle/manifests/$(OPERATOR_NAME).clusterserviceversion.yaml
	cat relatedImages.yaml >> bundle/manifests/$(OPERATOR_NAME).clusterserviceversion.yaml
	operator-sdk bundle validate ./bundle

# Build the bundle image.
.PHONY: bundle-build
bundle-build: bundle
	${CONTAINER_CLI} build -f bundle.Dockerfile -t $(BUNDLE_IMG) .
	${CONTAINER_CLI} push $(BUNDLE_IMG)
