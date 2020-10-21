#!/bin/bash
CLI=docker
REGISTRY="quay.io/krsacme"
TAG="${TAG:-v0.2.0}"

if [[ $1 == "all" ]]; then
    NAME=${REGISTRY}"/trex-container-server:"${TAG}
    $CLI build server -f server/Dockerfile -t $NAME
    $CLI push $NAME
fi

NAME=${REGISTRY}"/trex-container-app:"${TAG}
$CLI build app -f app/Dockerfile -t $NAME
$CLI push $NAME
