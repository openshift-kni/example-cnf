# Current Operator version
VERSION ?= 0.2.0
REGISTRY ?= quay.io
ORG ?= rh-nfv-int
DEFAULT_CHANNEL ?= alpha

CONTAINER_CLI ?= docker
CLUSTER_CLI ?= oc

# Default bundle image tag
BUNDLE_IMG ?= $(REGISTRY)/$(ORG)/testpmd-operator-bundle:v$(VERSION)
# Options for 'bundle-build'
ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

# Image URL to use all building/pushing image targets
IMG ?= $(REGISTRY)/$(ORG)/testpmd-operator:v$(VERSION)

all: docker-build docker-push

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
	cp config/manager/namespace.yaml testpmd-allinone.yaml
	echo "---" >> testpmd-allinone.yaml
	$(KUSTOMIZE) build config/default >> testpmd-allinone.yaml

# Undeploy controller in the configured Kubernetes cluster in ~/.kube/config
undeploy: kustomize
	$(KUSTOMIZE) build config/default | ${CLUSTER_CLI} delete -f -

# Build the docker image
docker-build:
	${CONTAINER_CLI} build . -t ${IMG}

# Push the docker image
docker-push:
	${CONTAINER_CLI} push ${IMG}

PATH  := $(PATH):$(PWD)/bin
SHELL := env PATH=$(PATH) /bin/sh
OS    = $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH  = $(shell uname -m | sed 's/x86_64/amd64/')
OSOPER   = $(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/apple-darwin/' | sed 's/linux/linux-gnu/')
ARCHOPER = $(shell uname -m )

kustomize:
ifeq (, $(shell which kustomize 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p bin ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v3.5.4/kustomize_v3.5.4_$(OS)_$(ARCH).tar.gz | tar xzf - -C bin/ ;\
	}
KUSTOMIZE=$(realpath ./bin/kustomize)
else
KUSTOMIZE=$(shell which kustomize)
endif

ansible-operator:
ifeq (, $(shell which ansible-operator 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p bin ;\
	curl -LO https://github.com/operator-framework/operator-sdk/releases/download/v1.0.0/ansible-operator-v1.0.0-$(ARCHOPER)-$(OSOPER) ;\
	mv ansible-operator-v1.0.0-$(ARCHOPER)-$(OSOPER) ./bin/ansible-operator ;\
	chmod +x ./bin/ansible-operator ;\
	}
ANSIBLE_OPERATOR=$(realpath ./bin/ansible-operator)
else
ANSIBLE_OPERATOR=$(shell which ansible-operator)
endif

.PHONY: bundle-check
bundle-check:
	@echo -n "This will override bundle.Dockerfile, needed only for version change and CSV/CRD/RBAC changes. Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]

# Generate bundle manifests and metadata, then validate generated files.
.PHONY: bundle
bundle: bundle-check kustomize
	operator-sdk generate kustomize manifests -q
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
	$(KUSTOMIZE) build config/manifests | operator-sdk generate bundle -q --overwrite --version $(VERSION) $(BUNDLE_METADATA_OPTS)
	operator-sdk bundle validate ./bundle

# Build the bundle image.
.PHONY: bundle-build
bundle-build:
	${CONTAINER_CLI} build -f bundle.Dockerfile -t $(BUNDLE_IMG) .
	${CONTAINER_CLI} push $(BUNDLE_IMG)
