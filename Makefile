SHELL 		    := /bin/bash

DIRS                := testpmd-container-app trex-container-app cnf-app-mac-operator testpmd-lb-operator testpmd-operator trex-operator nfv-example-cnf-index

# Print the possible targets and a short description
.PHONY: targets
targets:
	@awk -F: '/^.PHONY/ {print $$2}' Makefile | grep -v targets | column -t -s '#'

.PHONY: all # Build and push all images
all: build-all push-all

.PHONY: build-all # Build all images
build-all:
	@set -ex; for d in $(DIRS); do make -C $$d build-all SHA=$(SHA); done

.PHONY: push-all # Push all images
push-all:
	@set -ex; for d in $(DIRS); do make -C $$d push-all SHA=$(SHA); done
