VERSION        := 0.2.9
TAG            := v$(VERSION)
REGISTRY       ?= quay.io
ORG            ?= rh-nfv-int
CONTAINER_CLI  ?= podman
CLUSTER_CLI    ?= oc
INDEX_NAME     := nfv-example-cnf-catalog
INDEX_IMG      ?= $(REGISTRY)/$(ORG)/$(INDEX_NAME):$(TAG)
# Don't use latest until FBC has been sorted out
OPM_VERSION    ?= 1.19.5
OPM_REPO       ?= https://github.com/operator-framework/operator-registry
OS             := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH           := $(shell uname -m | sed 's/x86_64/amd64/')
OPERATORS_LIST := operators.cfg
SHELL          := /bin/bash

all: index-build index-push

# Build the index image
index-build: opm
	@{ \
	set -e ;\
	source ./$(OPERATORS_LIST) ;\
	BUNDLES_DIGESTS='' ;\
	for OPERATOR in $${OPERATORS[@]}; do \
    	operator_bundle=$${OPERATOR/:*}-bundle ;\
    	operator_version=$${OPERATOR/*:} ;\
    	operator_digest=$$(skopeo inspect docker://$(REGISTRY)/$(ORG)/$${operator_bundle}:$${operator_version} | jq -r '.Digest') ;\
	BUNDLES_DIGESTS+=$(REGISTRY)/$(ORG)/$${operator_bundle}@$${operator_digest}, ;\
	done ;\
	$(OPM) index add --bundles $${BUNDLES_DIGESTS%,} --tag $(INDEX_IMG) ;\
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
