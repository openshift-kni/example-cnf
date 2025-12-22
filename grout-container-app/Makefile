SHELL           := /bin/bash

DATE            ?= $(shell date --utc +%Y%m%d%H%M)
SHA             ?= $(shell git rev-parse --short HEAD)
VERSION         ?= 0.2.5
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
all: build-all push-all rmi-all

.PHONY: cnfapp-dependencies # Get dependencies for cnfapp
cnfapp-dependencies:
	mkdir cnfapp/utils
	cp ../utils/webserver.go cnfapp/utils/webserver.go

.PHONY: build-all # Build ALL images
build-all: build-cnfapp

.PHONY: build-cnfapp # Build cnfapp
build-cnfapp: cnfapp-dependencies
	if [ -n "$(RELEASE)" ]; then \
	$(CONTAINER_CLI) build $(@:build-%=%) -f $(@:build-%=%)/Dockerfile -t "$(REGISTRY)/$(ORG)/grout-container-app-$(@:build-%=%):v$(TAG)" -t "$(REGISTRY)/$(ORG)/grout-container-app-$(@:build-%=%):v$(VERSION)" $(CONTAINER_ARGS); \
	else \
	$(CONTAINER_CLI) build $(@:build-%=%) -f $(@:build-%=%)/Dockerfile --label quay.expires-after=1w -t "$(REGISTRY)/$(ORG)/grout-container-app-$(@:build-%=%):v$(TAG)" $(CONTAINER_ARGS); \
	fi

.PHONY: push-all # Push ALL images
push-all: push-cnfapp

.PHONY: push-cnfapp # Push cnfapp
push-cnfapp: build-cnfapp
	$(CONTAINER_CLI) push "$(REGISTRY)/$(ORG)/grout-container-app-$(@:push-%=%):v$(TAG)"
	if [ -n "$(RELEASE)" ]; then \
	$(CONTAINER_CLI) push "$(REGISTRY)/$(ORG)/grout-container-app-$(@:push-%=%):v$(VERSION)"; \
	fi

.PHONY: rmi-all # Remove ALL images locally
rmi-all: rmi-cnfapp

.PHONY: rmi-cnfapp # Remove cnfapp image from local storage
rmi-cnfapp: push-cnfapp
	$(CONTAINER_CLI) rmi -f "$(REGISTRY)/$(ORG)/grout-container-app-$(@:rmi-%=%):v$(TAG)"
	if [ -n "$(RELEASE)" ]; then \
	$(CONTAINER_CLI) rmi -f "$(REGISTRY)/$(ORG)/grout-container-app-$(@:rmi-%=%):v$(VERSION)"; \
	fi

.PHONY: version # Display the version
version:
	@echo $(VERSION)
