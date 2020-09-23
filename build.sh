#!/bin/bash
CLI=docker
REGISTRY="quay.io/krsacme"
TAG="${TAG:-v0.1.1}"
NAME=${REGISTRY}"/testpmd-container-app:"${TAG}
$CLI build . -t $NAME && $CLI push $NAME

if [[ $1 == "all" ]]; then
    CNI_IMG_NAME=${REGISTRY}"/testpmd-container-app-mac-fix:"${TAG}
    $CLI build sriov-cni --file sriov-cni/Dockerfile -t $CNI_IMG_NAME && $CLI push $CNI_IMG_NAME
fi
