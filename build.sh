#!/bin/bash

set -e

CLI=docker
ORG="rh-nfv-int"
REGISTRY="quay.io/${ORG}"
TAG="${TAG:-v0.2.0}"

LIST=""
if [[ $1 == "all" || $1 == "testpmd" ]]; then
    LIST="${LIST} testpmd"
fi
if [[ $1 == "all" || $1 == "monitor" ]]; then
    LIST="${LIST} monitor"
fi
if [[ $1 == "all" || $1 == "mac" ]]; then
    LIST="${LIST} mac"
fi

for item in ${LIST}; do
    IMAGE="${REGISTRY}/testpmd-container-app-${item}:${TAG}"
    $CLI build ${item} -f ${item}/Dockerfile -t $IMAGE
    $CLI push $IMAGE
done
