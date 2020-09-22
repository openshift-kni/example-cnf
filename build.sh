#!/bin/bash

REGISTRY="quay.io/krsacme"
TAG="${TAG:-v0.1.1}"
NAME=${REGISTRY}"/trex-container-app:"${TAG}
docker build . -t $NAME && docker push $NAME
