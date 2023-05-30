SHELL 		    := /bin/bash

VERSION         ?= 0.2.6
REGISTRY        ?= quay.io
ORG             ?= rh-nfv-int
CONTAINER_CLI   ?= podman
TAG             ?= v$(VERSION)

ifneq ($(origin FORCE), undefined)
	CONTAINER_ARGS := --no-cache
endif

# Print the possible targets and a short description
targets:
	@awk -F: '/^.PHONY/ {print $$2}' Makefile | column -t -s '#'

.PHONY: all # Build and push all images
all: build-all push-all

.PHONY: build-all # Build ALL images
build-all: build-server build-app

.PHONY: build-server # Build TRex Server
build-server:
	@$(CONTAINER_CLI) build $(@:build-%=%) -f $(@:build-%=%)/Dockerfile -t "$(REGISTRY)/$(ORG)/trex-container-$(@:build-%=%):$(TAG)" $(CONTAINER_ARGS)

.PHONY: build-app # Build TRex App
build-app:
	@$(CONTAINER_CLI) build $(@:build-%=%) -f $(@:build-%=%)/Dockerfile -t "$(REGISTRY)/$(ORG)/trex-container-$(@:build-%=%):$(TAG)" $(CONTAINER_ARGS)

.PHONY: push-all # Push ALL images
push-all: push-server push-app

.PHONY: push-testpmd # Push TRex Server
push-server: build-server
	@$(CONTAINER_CLI) push "$(REGISTRY)/$(ORG)/trex-container-$(@:push-%=%):$(TAG)"

.PHONY: push-app # Push TRex App
push-app: build-app
	@$(CONTAINER_CLI) push "$(REGISTRY)/$(ORG)/trex-container-$(@:push-%=%):$(TAG)"
