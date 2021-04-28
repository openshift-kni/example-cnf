#!/bin/bash

set -e

TAG="${TAG:-v0.2.2}"

CLI=${CLI:="podman"}
ORG=${ORG:="rh-nfv-int"}
REGISTRY="quay.io/${ORG}"

EXTRA=""
if [[ $2 == "force" ]]; then
    EXTRA="--no-cache"
fi

LIST=""
if [[ $1 == "all" || $1 == "server" ]]; then
    LIST="${LIST} server"
fi
if [[ $1 == "all" || $1 == "app" ]]; then
    LIST="${LIST} app"
fi

for item in ${LIST}; do
    IMAGE="${REGISTRY}/trex-container-${item}:${TAG}"
    $CLI build ${item} -f ${item}/Dockerfile -t $IMAGE $EXTRA
    $CLI push $IMAGE
done
