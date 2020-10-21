#!/bin/bash

set -e

CLI=docker
REGISTRY="quay.io/krsacme"
TAG="${TAG:-v0.2.0}"

MONITOR="${REGISTRY}/testpmd-container-app-monitor:${TAG}"
$CLI build monitor -f monitor/Dockerfile -t $MONITOR
$CLI push $MONITOR

if [[ $1 == "all" ]]; then
    NAME=${REGISTRY}"/testpmd-container-app:"${TAG}
    $CLI build testpmd -f testpmd/Dockerfile -t $NAME
    $CLI push $NAME

    CNI_IMG_NAME=${REGISTRY}"/testpmd-container-app-mac-fix:"${TAG}
    $CLI build sriov-cni --file sriov-cni/Dockerfile -t $CNI_IMG_NAME
    $CLI push $CNI_IMG_NAME
fi
