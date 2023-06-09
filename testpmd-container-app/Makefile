SHELL           := /bin/bash

DATE            ?= $(shell date --utc +%Y%m%d%H%M)
SHA             ?= $(shell git rev-parse --short HEAD)
VERSION         ?= 0.2.4
REGISTRY        ?= quay.io
ORG             ?= rh-nfv-int
CONTAINER_CLI   ?= podman
TAG             ?= $(VERSION)-$(DATE).$(SHA)
TESTPMD_LB_REPO ?= https://github.com/krsacme/testpmd-as-load-balancer.git

ifneq ($(origin FORCE), undefined)
	CONTAINER_ARGS := --no-cache
endif

# Print the possible targets and a short description
targets:
	@awk -F: '/^.PHONY/ {print $$2}' Makefile | column -t -s '#'

.PHONY: all # Build and push all images
all: build-all push-all

.PHONY: testpmd-dependencies # Get dependencies for testpmd
testpmd-dependencies:
	if [[ ! -d testpmd/testpmd-as-load-balancer ]]; then \
	git clone $(TESTPMD_LB_REPO) testpmd/testpmd-as-load-balancer; \
	fi

.PHONY: build-all # Build ALL images
build-all: build-testpmd build-mac build-listener

.PHONY: build-testpmd # Build testpmd
build-testpmd: testpmd-dependencies
	if [ -n "$(RELEASE)" ]; then \
	$(CONTAINER_CLI) build $(@:build-%=%) -f $(@:build-%=%)/Dockerfile -t "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:build-%=%):v$(TAG)" -t "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:build-%=%):v$(VERSION)" $(CONTAINER_ARGS); \
	else \
	$(CONTAINER_CLI) build $(@:build-%=%) -f $(@:build-%=%)/Dockerfile --label quay.expires-after=2w -t "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:build-%=%):v$(TAG)" $(CONTAINER_ARGS); \
	fi

.PHONY: build-mac # Build mac
build-mac:
	if [ -n "$(RELEASE)" ]; then \
	$(CONTAINER_CLI) build $(@:build-%=%) -f $(@:build-%=%)/Dockerfile -t "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:build-%=%):v$(TAG)" -t "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:build-%=%):v$(VERSION)" $(CONTAINER_ARGS); \
	else \
	$(CONTAINER_CLI) build $(@:build-%=%) -f $(@:build-%=%)/Dockerfile --label quay.expires-after=2w -t "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:build-%=%):v$(TAG)" $(CONTAINER_ARGS); \
	fi

.PHONY: build-listener # Build listener
build-listener:
	if [ -n "$(RELEASE)" ]; then \
	$(CONTAINER_CLI) build $(@:build-%=%) -f $(@:build-%=%)/Dockerfile -t "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:build-%=%):v$(TAG)" -t "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:build-%=%):v$(VERSION)" $(CONTAINER_ARGS); \
	else \
	$(CONTAINER_CLI) build $(@:build-%=%) -f $(@:build-%=%)/Dockerfile --label quay.expires-after=2w -t "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:build-%=%):v$(TAG)" $(CONTAINER_ARGS); \
	fi

.PHONY: clean # Delete untracked changes
clean:
	rm -Rf testpmd/testpmd-as-load-balancer

.PHONY: push-all # Push ALL images
push-all: push-testpmd push-mac push-listener

.PHONY: push-testpmd # Push testpmd
push-testpmd: build-testpmd
	$(CONTAINER_CLI) push "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:push-%=%):v$(TAG)"
	if [ -n "$(RELEASE)" ]; then \
	$(CONTAINER_CLI) push "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:push-%=%):v$(VERSION)"; \
	fi

.PHONY: push-mac # Push mac
push-mac: build-mac
	$(CONTAINER_CLI) push "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:push-%=%):v$(TAG)"
	if [ -n "$(RELEASE)" ]; then \
	$(CONTAINER_CLI) push "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:push-%=%):v$(VERSION)"; \
	fi

.PHONY: push-listener # Push testpmd
push-listener: build-listener
	$(CONTAINER_CLI) push "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:push-%=%):v$(TAG)"
	if [ -n "$(RELEASE)" ]; then \
	$(CONTAINER_CLI) push "$(REGISTRY)/$(ORG)/testpmd-container-app-$(@:push-%=%):v$(VERSION)"; \
	fi

.PHONY: version # Display the version
version:
	@echo $(VERSION)
