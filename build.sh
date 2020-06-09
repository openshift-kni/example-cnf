#!/bin/bash

REGISTRY="quay.io/krsacme"
TAG="latest"
NAME=${REGISTRY}"/testpmd-container-app:"${TAG}
docker build . -t $NAME && docker push $NAME
