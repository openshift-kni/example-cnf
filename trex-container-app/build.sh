#!/bin/bash

set -e

if [[ "$1" == "-h" ]] ; then
    echo "A tool that allows you to build TRex application containers."
    echo
    echo "Usage:"
    echo "    `basename $0` [list of containers to build] [extra options]"
    echo
    echo "List of containers to build:"
    echo "    all: build two containers: server and app"
    echo "    app: build app container"
    echo "    server: build server container"
    echo
    echo "Extra options:"
    echo "    force: use --no-cache for the image build"
    exit 0
fi

TAG="${TAG:-v0.2.10}"

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
