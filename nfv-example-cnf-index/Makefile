DATE           ?= $(shell date --utc +%Y%m%d%H%M)
SHA            ?= $(shell git rev-parse --short HEAD)
VERSION        := 0.3.9
TAG            := $(VERSION)-$(DATE).$(SHA)
REGISTRY       ?= quay.io
ORG            ?= rh-nfv-int
CONTAINER_CLI  ?= podman
CLUSTER_CLI    ?= oc
INDEX_NAME     := nfv-example-cnf-catalog
INDEX_IMG      ?= $(REGISTRY)/$(ORG)/$(INDEX_NAME):v$(TAG)
REL_INDEX_IMG  ?= $(REGISTRY)/$(ORG)/$(INDEX_NAME):v$(VERSION)
BUILD_PATH     ?= ./build
OPM_VERSION    ?= latest
OPM_REPO       ?= https://github.com/operator-framework/operator-registry
OS             := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH           := $(shell uname -m | sed 's/x86_64/amd64/')
OPERATORS_LIST := operators.cfg
SHELL          := /bin/bash

all: index-build index-push

build-all: index-build

push-all: index-push

# Clean up
clean:
	@rm -rf $(BUILD_PATH)

# Build the index image
index-build: opm
	@{ \
	set -e ;\
	mkdir -p $(BUILD_PATH)/$(INDEX_NAME) ;\
	rm -f $(BUILD_PATH)/$(INDEX_NAME)/index.yml ;\
	cp "$(INDEX_NAME).Dockerfile" $(BUILD_PATH)/ ;\
	./generate-operators-cfg.sh ./$(OPERATORS_LIST) ;\
	cat ./$(OPERATORS_LIST);\
	source ./$(OPERATORS_LIST) ;\
	for OPERATOR in $${OPERATORS[@]}; do \
		operator_bundle=$${OPERATOR/:*}-bundle ;\
		operator_version=$${OPERATOR/*:} ;\
		operator_name=$${OPERATOR/:*} ;\
		operator_manifest=$$(skopeo inspect docker://$(REGISTRY)/$(ORG)/$${operator_bundle}:$${operator_version}) ;\
		operator_digest=$$(jq -r '.Digest' <<< $${operator_manifest}) ;\
		bundle_digest=$(REGISTRY)/$(ORG)/$${operator_bundle}@$${operator_digest} ;\
		echo "operator=$${operator_name} operator_version=$${operator_version} operator_digest=$${operator_digest}" ;\
		default_channel=$$(jq -r '.Labels."operators.operatorframework.io.bundle.channel.default.v1"' <<< $${operator_manifest}) ;\
		$(OPM) init $${operator_name} --default-channel=$${default_channel} --output=yaml >> $(BUILD_PATH)/$(INDEX_NAME)/index.yml ;\
		rendered=$$($(OPM) render $${bundle_digest} --output=yaml) ;\
		echo "$${rendered}" >> $(BUILD_PATH)/$(INDEX_NAME)/index.yml ;\
		operator_name_version=$$(sed -n -e 's/^name: //p'<<< "$$rendered") ;\
		echo "$${operator_name_version}" ;\
		channel="---\nschema: olm.channel\npackage: $${operator_name}\nname: $${default_channel}\nentries:\n  - name: $${operator_name_version}" ;\
		echo -e $${channel} >> $(BUILD_PATH)/$(INDEX_NAME)/index.yml ;\
	done ;\
	echo "validating the catalog" ;\
	$(OPM) validate $(BUILD_PATH)/$(INDEX_NAME) ;\
	if [ -n "$(RELEASE)" ]; then \
	BUILDAH_FORMAT=docker podman build $(BUILD_PATH) -f $(BUILD_PATH)/$(INDEX_NAME).Dockerfile -t $(INDEX_IMG) -t $(REL_INDEX_IMG) ;\
	else \
	BUILDAH_FORMAT=docker podman build $(BUILD_PATH) -f $(BUILD_PATH)/$(INDEX_NAME).Dockerfile --label quay.expires-after=1w -t $(INDEX_IMG) ;\
	fi; \
	rm -rf $(BUILD_PATH) ;\
	}

# Push the index image
index-push:
	$(CONTAINER_CLI) push $(INDEX_IMG)
	if [ -n "$(RELEASE)" ]; then \
	$(CONTAINER_CLI) push $(REL_INDEX_IMG); \
	fi

# Installs opm if is not available
.PHONY: opm
OPM = $(shell pwd)/bin/opm
opm:
ifeq (,$(wildcard $(OPM)))
ifeq (,$(shell which opm 2>/dev/null))
	@{ \
	set -ex ;\
	mkdir -p $(dir $(OPM)) ;\
	OPM_TAG=v$(OPM_VERSION) ;\
	if [[ $(OPM_VERSION) == "latest" ]]; then \
	OPM_TAG=$$(curl -sI $(OPM_REPO)/releases/latest | awk '/^location:/ {print $$2}' | xargs basename | tr -d '\r') ;\
	fi ;\
	curl -sLo $(OPM) $(OPM_REPO)/releases/download/$${OPM_TAG}/$(OS)-$(ARCH)-opm ;\
	chmod u+x $(OPM) ;\
	}
else
OPM=$(shell which opm)
endif
endif

.PHONY: version # Display the version
version:
	@echo $(VERSION)
