#!/bin/bash

set -e

TAG=${TAG:-"v0.2.17"}

CLI=${CLI:="podman"}
ORG=${ORG:="rh-nfv-int"}
REGISTRY="quay.io/${ORG}"
PULL=${PULL:="0"}

EXTRA=""
if [[ $2 == "force" ]]; then
    EXTRA="--no-cache"
fi

LIST=""
if [[ $1 == "all" || $1 == "cnfapp" ]]; then
    LIST="${LIST} cnfapp"
fi

for item in ${LIST}; do
    IMAGE="${REGISTRY}/testpmd-container-app-${item}:${TAG}"
    $CLI build ${item} -f ${item}/Dockerfile -t $IMAGE $EXTRA
    $CLI push $IMAGE
done
