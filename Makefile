VERSION        := 0.3.1
TAG            := v$(VERSION)
REGISTRY       ?= quay.io
ORG            ?= rh-nfv-int
CONTAINER_CLI  ?= podman
CLUSTER_CLI    ?= oc
INDEX_NAME     := nfv-example-cnf-catalog
INDEX_IMG      ?= $(REGISTRY)/$(ORG)/$(INDEX_NAME):$(TAG)
BUILD_PATH     ?= ./build
OPM_VERSION    ?= latest
OPM_REPO       ?= https://github.com/operator-framework/operator-registry
OS             := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH           := $(shell uname -m | sed 's/x86_64/amd64/')
OPERATORS_LIST := operators.cfg
SHELL          := /bin/bash

all: index-build index-push

# Clean up
clean:
	@rm -rf $(BUILD_PATH)

# Build the index image
index-build: opm
	@{ \
	set -e ;\
	mkdir -p $(BUILD_PATH)/$(INDEX_NAME) ;\
	cp "$(INDEX_NAME).Dockerfile" $(BUILD_PATH)/ ;\
	source ./$(OPERATORS_LIST) ;\
	for OPERATOR in $${OPERATORS[@]}; do \
		operator_bundle=$${OPERATOR/:*}-bundle ;\
		operator_version=$${OPERATOR/*:} ;\
		operator_name=$${OPERATOR/:*} ;\
		operator_manifest=$$(skopeo inspect docker://$(REGISTRY)/$(ORG)/$${operator_bundle}:$${operator_version}) ;\
		operator_digest=$$(jq -r '.Digest' <<< $${operator_manifest}) ;\
		bundle_digest=$(REGISTRY)/$(ORG)/$${operator_bundle}@$${operator_digest} ;\
		default_channel=$$(jq -r '.Labels."operators.operatorframework.io.bundle.channel.default.v1"' <<< $${operator_manifest}) ;\
		channel="---\nschema: olm.channel\npackage: $${operator_name}\nname: $${default_channel}\nentries:\n  - name: $${operator_name}.$${operator_version}" ;\
		$(OPM) init $${operator_name} --default-channel=$${default_channel} --output=yaml >> $(BUILD_PATH)/$(INDEX_NAME)/index.yml ;\
		$(OPM) render $${bundle_digest} --output=yaml >> $(BUILD_PATH)/$(INDEX_NAME)/index.yml ;\
		echo -e $${channel} >> $(BUILD_PATH)/$(INDEX_NAME)/index.yml ;\
	done ;\
	$(OPM) validate $(BUILD_PATH)/$(INDEX_NAME) ;\
	BUILDAH_FORMAT=docker podman build $(BUILD_PATH) -f $(BUILD_PATH)/$(INDEX_NAME).Dockerfile -t $(INDEX_IMG) ;\
	rm -rf $(BUILD_PATH) ;\
	}

# Push the index image
index-push:
	$(CONTAINER_CLI) push $(INDEX_IMG)

# Installs opm if is not available
.PHONY: opm
OPM = $(shell pwd)/bin/opm
opm:
ifeq (,$(wildcard $(OPM)))
ifeq (,$(shell which opm 2>/dev/null))
	@{ \
	set -e ;\
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
