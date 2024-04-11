# VERSION defines the project version for the bundle.
# Update this value when you upgrade the version of your project.
# To re-generate a bundle for another specific version without changing the standard setup, you can:
# - use the VERSION as arg of the bundle target (e.g make bundle VERSION=0.0.2)
# - use environment variables to overwrite this value (e.g export VERSION=0.0.2)
VERSION ?= 0.2.17

# Set the Operator SDK version to use. By default, what is installed on the system is used.
# This is useful for CI or a project to utilize a specific version of the operator-sdk toolkit.
OPERATOR_SDK_VER ?= 1.33.0

# Other custom variables
SHELL            := /bin/bash
DATE             ?= $(shell date --utc +%Y%m%d%H%M)
SHA              ?= $(shell git rev-parse --short HEAD)
TAG              := $(VERSION)-$(DATE).$(SHA)
REGISTRY         ?= quay.io
ORG              ?= rh-nfv-int
DEFAULT_CHANNEL  ?= alpha
CONTAINER_CLI    ?= podman
CLUSTER_CLI      ?= oc
OPERATOR_NAME    := trex-operator
KUSTOMIZE_VER    := 5.0.1
OPM_VER          := 1.23.0
TREX_VER         ?= v$(shell bash -c '. ../versions.cfg; echo "$${VERSIONS[trex-container-app]}"')

# CHANNELS define the bundle channels used in the bundle.
# Add a new line here if you would like to change its default config. (E.g CHANNELS = "candidate,fast,stable")
# To re-generate a bundle for other specific channels without changing the standard setup, you can:
# - use the CHANNELS as arg of the bundle target (e.g make bundle CHANNELS=candidate,fast,stable)
# - use environment variables to overwrite this value (e.g export CHANNELS="candidate,fast,stable")
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

# IMAGE_TAG_BASE defines the docker.io namespace and part of the image name for remote images.
# This variable is used to construct full image tags for bundle and catalog images.
IMAGE_TAG_BASE ?= $(REGISTRY)/$(ORG)/$(OPERATOR_NAME)

# BUNDLE_IMG defines the image:tag used for the bundle.
# You can use it as an arg. (E.g make bundle-build BUNDLE_IMG=<some-registry>/<project-name-bundle>:<tag>)
BUNDLE_IMG ?= $(IMAGE_TAG_BASE)-bundle:v$(TAG)
REL_BUNDLE_IMG ?= $(IMAGE_TAG_BASE)-bundle:v$(VERSION)

# BUNDLE_GEN_FLAGS are the flags passed to the operator-sdk generate bundle command
BUNDLE_GEN_FLAGS ?= -q --overwrite --version $(TAG) $(BUNDLE_METADATA_OPTS)

# USE_IMAGE_DIGESTS defines if images are resolved via tags or digests
# You can enable this value if you would like to use SHA Based Digests
# To enable set flag to true
USE_IMAGE_DIGESTS ?= false
ifeq ($(USE_IMAGE_DIGESTS), true)
	BUNDLE_GEN_FLAGS += --use-image-digests
endif

# Image URL to use all building/pushing image targets
IMG ?= $(IMAGE_TAG_BASE):v$(TAG)
REL_IMG ?= $(IMAGE_TAG_BASE):v$(VERSION)

# Our general, custom tasks

.PHONY: all
all: operator-all bundle-all

.PHONY: build-all
build-all: operator-build bundle-build

.PHONY: push-all
push-all: operator-push bundle-push

# Operator build and push
.PHONY: operator-all
operator-all: operator-build operator-push

# Bundle build and push
.PHONY: bundle-all
bundle-all: bundle-build bundle-push

.PHONY: run
ANSIBLE_ROLES_PATH?="$(shell pwd)/roles"
run: ansible-operator ## Run against the configured Kubernetes cluster in ~/.kube/config
	$(ANSIBLE_OPERATOR) run

.PHONY: install
install: kustomize ## Install CRDs into the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/crd | ${CLUSTER_CLI} apply -f -

.PHONY: uninstall
uninstall: kustomize ## Uninstall CRDs from the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/crd | ${CLUSTER_CLI} delete -f -

.PHONY: deploy
deploy: kustomize ## Deploy controller to the K8s cluster specified in ~/.kube/config.
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	${CLUSTER_CLI} apply -f config/manager/namespace.yaml
	$(KUSTOMIZE) build config/default | ${CLUSTER_CLI} apply -f -
	cp config/manager/namespace.yaml trex-allinone.yaml
	echo "---" >> trex-allinone.yaml
	$(KUSTOMIZE) build config/default >> trex-allinone.yaml

# Custom tasks for our operator build and push
# Undeploy controller from the K8s cluster specified in ~/.kube/config.
.PHONY: undeploy
undeploy:
	$(KUSTOMIZE) build config/default | ${CLUSTER_CLI} delete -f -

# Ensure proper digests for trex-container-app and trex-container-server
.PHONY: ensure_digests
ensure_digests:
	cp roles/app/defaults/main.yml.in roles/app/defaults/main.yml
	DIGEST=$$(skopeo inspect docker://quay.io/rh-nfv-int/trex-container-app:$(TREX_VER)|jq -r .Digest) && [ -n "$${DIGEST}" ] && sed -i -e "s/trex-container-app@.*/trex-container-app@$${DIGEST}\"   # $(TREX_VER)/" roles/app/defaults/main.yml
	cp roles/server/defaults/main.yml.in roles/server/defaults/main.yml
	DIGEST=$$(skopeo inspect docker://quay.io/rh-nfv-int/trex-container-server:$(TREX_VER)|jq -r .Digest) && [ -n "$${DIGEST}" ] && sed -i -e "s/trex-container-server@.*/trex-container-server@$${DIGEST}\"   # $(TREX_VER)/" roles/server/defaults/main.yml
	DIGEST=$$(skopeo inspect docker://quay.io/rh-nfv-int/trex-container-app:$(TREX_VER)|jq -r .Digest) && [ -n "$${DIGEST}" ] && sed -i -e "s/trex-container-app@.*/trex-container-app@$${DIGEST}\"   # $(TREX_VER)/" roles/server/defaults/main.yml

# Build the operator image
.PHONY: operator-build
operator-build: ensure_digests
	if [ -n "$(RELEASE)" ]; then \
	BUILDAH_FORMAT=docker ${CONTAINER_CLI} build . -t ${IMG}  -t ${REL_IMG} ;\
	else \
	BUILDAH_FORMAT=docker ${CONTAINER_CLI} build . --label quay.expires-after=2w -t ${IMG} ;\
	fi

# Push the operator image
.PHONY: operator-push
operator-push:
	if [ -n "$(RELEASE)" ]; then \
	${CONTAINER_CLI} push ${REL_IMG} ;\
	fi
	${CONTAINER_CLI} push ${IMG}

PATH  := $(PATH):$(PWD)/bin
SHELL := env PATH=$(PATH) /bin/sh
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')

# Download kustomize locally if necessary in $(pwd)/bin
.PHONY: kustomize
KUSTOMIZE = $(shell pwd)/bin/kustomize
kustomize: ## Download kustomize locally if necessary.
ifeq (,$(wildcard $(KUSTOMIZE)))
ifeq (,$(shell which kustomize 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(KUSTOMIZE)) ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v$(KUSTOMIZE_VER)/kustomize_v$(KUSTOMIZE_VER)_$(OS)_$(ARCH).tar.gz | \
	tar xzf - -C bin/ ;\
	}
else
KUSTOMIZE = $(shell which kustomize)
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
	curl -sSLo $(ANSIBLE_OPERATOR) https://github.com/operator-framework/ansible-operator-plugins/releases/download/v$(OPERATOR_SDK_VER)/ansible-operator_$(OS)_$(ARCH) ;\
	chmod +x $(ANSIBLE_OPERATOR) ;\
	}
else
ANSIBLE_OPERATOR = $(shell which ansible-operator)
endif
endif

.PHONY: operator-sdk
OPERATOR_SDK ?= ./bin/operator-sdk
operator-sdk: ## Download operator-sdk locally if necessary.
ifeq (,$(wildcard $(OPERATOR_SDK)))
ifeq (, $(shell which operator-sdk 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(OPERATOR_SDK)) ;\
	curl -sSLo $(OPERATOR_SDK) https://github.com/operator-framework/operator-sdk/releases/download/v$(OPERATOR_SDK_VER)/operator-sdk_$(OS)_$(ARCH) ;\
	chmod +x $(OPERATOR_SDK) ;\
	}
else
OPERATOR_SDK = $(shell which operator-sdk)
endif
endif

# Custom bundle-related tasks

## Generate bundle manifests and metadata, then validate generated files.
.PHONY: bundle
bundle: kustomize operator-sdk
	$(OPERATOR_SDK) generate kustomize manifests -q
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
	$(KUSTOMIZE) build config/manifests | $(OPERATOR_SDK) generate bundle $(BUNDLE_GEN_FLAGS)
	DIGEST=$$(skopeo inspect docker://$(IMG) | jq -r '.Digest') && sed -i -e 's/\(\s*image: .*\):v'$(TAG)'/\1@'$${DIGEST}'/' bundle/manifests/$(OPERATOR_NAME).clusterserviceversion.yaml
	sed -i -e '/^# Copy.*/i LABEL com.redhat.openshift.versions="v4.12"\nLABEL com.redhat.delivery.backport=false\nLABEL com.redhat.delivery.operator.bundle=true' bundle.Dockerfile
	cp relatedImages.yaml.in relatedImages.yaml
	DIGEST=$$(skopeo inspect docker://quay.io/rh-nfv-int/trex-container-server:$(TREX_VER)|jq -r .Digest) && [ -n "$${DIGEST}" ] && sed -i -e "s/trex-container-server@.*/trex-container-server@$${DIGEST}\"   # $(TREX_VER)/" relatedImages.yaml
	DIGEST=$$(skopeo inspect docker://quay.io/rh-nfv-int/trex-container-app:$(TREX_VER)|jq -r .Digest) && [ -n "$${DIGEST}" ] && sed -i -e "s/trex-container-app@.*/trex-container-app@$${DIGEST}\"   # $(TREX_VER)/" relatedImages.yaml
	cat relatedImages.yaml >> bundle/manifests/$(OPERATOR_NAME).clusterserviceversion.yaml
	$(OPERATOR_SDK) bundle validate ./bundle
	echo "bundle image=$(IMG)"

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
.PHONY: bundle-tag
bundle-tag:
	${CONTAINER_CLI} tag bundle $(BUNDLE_IMG)
	if [ -n "$(RELEASE)" ]; then \
	${CONTAINER_CLI} tag bundle $(REL_BUNDLE_IMG); \
	fi

# Push the BUNDLE_IMG
.PHONY: bundle-push
bundle-push: bundle-tag
	${CONTAINER_CLI} push $(BUNDLE_IMG)
	if [ -n "$(RELEASE)" ]; then \
	${CONTAINER_CLI} push $(REL_BUNDLE_IMG); \
	fi

.PHONY: version # Display the version
version:
	@echo $(VERSION)
# OPM task

# Download opm locally if necessary.
.PHONY: opm
OPM = ./bin/opm
opm:
ifeq (,$(wildcard $(OPM)))
ifeq (,$(shell which opm 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(OPM)) ;\
	curl -sSLo $(OPM) https://github.com/operator-framework/operator-registry/releases/download/v$(OPM_VER)/$(OS)-$(ARCH)-opm ;\
	chmod +x $(OPM) ;\
	}
else
OPM = $(shell which opm)
endif
endif

# A comma-separated list of bundle images (e.g. make catalog-build BUNDLE_IMGS=example.com/operator-bundle:v0.1.0,example.com/operator-bundle:v0.2.0).
# These images MUST exist in a registry and be pull-able.
BUNDLE_IMGS ?= $(BUNDLE_IMG)

# The image tag given to the resulting catalog image (e.g. make catalog-build CATALOG_IMG=example.com/operator-catalog:v0.2.0).
CATALOG_IMG ?= $(IMAGE_TAG_BASE)-catalog:v$(VERSION)

# Set CATALOG_BASE_IMG to an existing catalog image tag to add $BUNDLE_IMGS to that image.
ifneq ($(origin CATALOG_BASE_IMG), undefined)
FROM_INDEX_OPT := --from-index $(CATALOG_BASE_IMG)
endif

# Build a catalog image by adding bundle images to an empty catalog using the operator package manager tool, 'opm'.
# This recipe invokes 'opm' in 'semver' bundle add mode. For more information on add modes, see:
# https://github.com/operator-framework/community-operators/blob/7f1438c/docs/packaging-operator.md#updating-your-existing-operator
.PHONY: catalog-build
catalog-build: opm ## Build a catalog image.
	$(OPM) index add --container-tool ${CONTAINER_CLI} --mode semver --tag $(CATALOG_IMG) --bundles $(BUNDLE_IMGS) $(FROM_INDEX_OPT)

# Push the catalog image.
.PHONY: catalog-push
catalog-push: ## Push a catalog image.
	$(MAKE) ${CONTAINER_CLI} push IMG=$(CATALOG_IMG)
