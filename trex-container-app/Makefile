SHELL           := /bin/bash

DATE            ?= $(shell date --utc +%Y%m%d%H%M)
SHA             ?= $(shell git rev-parse --short HEAD)
VERSION         ?= 0.2.11
REGISTRY        ?= quay.io
ORG             ?= rh-nfv-int
CONTAINER_CLI   ?= podman
TAG             ?= $(VERSION)-$(DATE).$(SHA)

ifneq ($(origin FORCE), undefined)
	CONTAINER_ARGS := --no-cache
endif

# Print the possible targets and a short description
targets:
	@awk -F: '/^.PHONY/ {print $$2}' Makefile | column -t -s '#'

.PHONY: all # Build and push all images
all: build-all push-all

.PHONY: server-dependencies # Include dependencies for server
server-dependencies:
	mkdir server/utils
	cp ../utils/webserver.go server/utils/webserver.go

.PHONY: app-dependencies # Include dependencies for app
app-dependencies:
	mkdir app/utils
	cp ../utils/webserver.go app/utils/webserver.go

.PHONY: build-all # Build ALL images
build-all: build-server build-app

.PHONY: build-server # Build TRex Server
build-server: server-dependencies
	if [ -n "$(RELEASE)" ]; then \
	$(CONTAINER_CLI) build $(@:build-%=%) -f $(@:build-%=%)/Dockerfile -t "$(REGISTRY)/$(ORG)/trex-container-$(@:build-%=%):v$(TAG)" -t "$(REGISTRY)/$(ORG)/trex-container-$(@:build-%=%):v$(VERSION)" $(CONTAINER_ARGS); \
	else \
	$(CONTAINER_CLI) build $(@:build-%=%) -f $(@:build-%=%)/Dockerfile --label quay.expires-after=2w  -t "$(REGISTRY)/$(ORG)/trex-container-$(@:build-%=%):v$(TAG)" $(CONTAINER_ARGS); \
	fi

.PHONY: build-app # Build TRex App
build-app: app-dependencies
	if [ -n "$(RELEASE)" ]; then \
	$(CONTAINER_CLI) build $(@:build-%=%) -f $(@:build-%=%)/Dockerfile -t "$(REGISTRY)/$(ORG)/trex-container-$(@:build-%=%):v$(TAG)" -t "$(REGISTRY)/$(ORG)/trex-container-$(@:build-%=%):v$(VERSION)" $(CONTAINER_ARGS); \
	else \
	$(CONTAINER_CLI) build $(@:build-%=%) -f $(@:build-%=%)/Dockerfile --label quay.expires-after=2w  -t "$(REGISTRY)/$(ORG)/trex-container-$(@:build-%=%):v$(TAG)" $(CONTAINER_ARGS); \
	fi

.PHONY: push-all # Push ALL images
push-all: push-server push-app

.PHONY: push-server # Push TRex Server
push-server: build-server
	$(CONTAINER_CLI) push "$(REGISTRY)/$(ORG)/trex-container-$(@:push-%=%):v$(TAG)"
	if [ -n "$(RELEASE)" ]; then \
	$(CONTAINER_CLI) push "$(REGISTRY)/$(ORG)/trex-container-$(@:push-%=%):v$(VERSION)"; \
	fi

.PHONY: push-app # Push TRex App
push-app: build-app
	$(CONTAINER_CLI) push "$(REGISTRY)/$(ORG)/trex-container-$(@:push-%=%):v$(TAG)"
	if [ -n "$(RELEASE)" ]; then \
	$(CONTAINER_CLI) push "$(REGISTRY)/$(ORG)/trex-container-$(@:push-%=%):v$(VERSION)"; \
	fi

.PHONY: version # Display the version
version:
	@echo $(VERSION)
