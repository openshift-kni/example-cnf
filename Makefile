SHELL           := /bin/bash

DIRS            := testpmd-container-app trex-container-app cnf-app-mac-operator testpmd-operator trex-operator nfv-example-cnf-index

OPERATOR_SDK_VER:= 1.39.1

# Print the possible targets and a short description
.PHONY: targets
targets:
	@awk -F: '/^.PHONY/ {print $$2}' Makefile | grep -v targets | column -t -s '#'

.PHONY: all # Build and push all images
all:
	@set -ex; for d in $(shell env FORCE_BUILD=$(FORCE_BUILD) ./generate-versions.sh "versions.cfg" "${DATE}.${SHA}"); do make -C $$d all SHA=$(SHA) DATE=$(DATE) OPERATOR_SDK_VER=$(OPERATOR_SDK_VER) RELEASE=${RELEASE}; done

.PHONY: build-all # Build all images
build-all:
	@set -ex; for d in $(shell env FORCE_BUILD=$(FORCE_BUILD) ./generate-versions.sh "versions.cfg" "${DATE}.${SHA}"); do make -C $$d build-all SHA=$(SHA) DATE=$(DATE) OPERATOR_SDK_VER=$(OPERATOR_SDK_VER) RELEASE=${RELEASE}; done

.PHONY: version # Display all the versions
version:
	@for d in $(DIRS); do echo -n "$$d: "; make -sC $$d version; done
