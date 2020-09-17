#!/bin/bash

REGISTRY="quay.io/krsacme"
TAG="${TAG:-v0.1.0}"
NAME=${REGISTRY}"/trex-container-app:"${TAG}
docker build . -t $NAME && docker push $NAME
