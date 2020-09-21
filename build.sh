#!/bin/bash

REGISTRY="quay.io/krsacme"
TAG="${TAG:-v0.1.1}"
NAME=${REGISTRY}"/testpmd-container-app:"${TAG}
docker build . -t $NAME && docker push $NAME

CNI_IMG_NAME=${REGISTRY}"/testpmd-container-app-mac-fix:"${TAG}
docker build sriov-cni --file sriov-cni/Dockerfile -t $CNI_IMG_NAME && docker push $CNI_IMG_NAME
