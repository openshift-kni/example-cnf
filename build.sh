#!/bin/bash

REGISTRY="quay.io/krsacme"
TAG="${TAG:-latest}"
NAME=${REGISTRY}"/trex-container-app:"${TAG}
docker build . -t $NAME && docker push $NAME
