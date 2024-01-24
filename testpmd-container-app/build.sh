#!/bin/bash

set -e

TAG=${TAG:-"v0.2.7"}

CLI=${CLI:="podman"}
ORG=${ORG:="rh-nfv-int"}
REGISTRY="quay.io/${ORG}"
PULL=${PULL:="0"}

EXTRA=""
if [[ $2 == "force" ]]; then
    EXTRA="--no-cache"
fi

LIST=""
if [[ $1 == "all" || $1 == "testpmd" ]]; then
    LIST="${LIST} testpmd"
    if [ ! -d $PWD/testpmd/testpmd-as-load-balancer ]; then
        git clone https://github.com/krsacme/testpmd-as-load-balancer.git $PWD/testpmd/testpmd-as-load-balancer
    fi
    if [[ $PULL == "1" ]]; then
        pushd $PWD/testpmd/testpmd-as-load-balancer
        git -C $PWD checkout master
        git -C $PWD pull origin master
        popd
    fi
fi
if [[ $1 == "all" || $1 == "cnfapp" ]]; then
    LIST="${LIST} cnfapp"
fi
if [[ $1 == "all" || $1 == "listener" ]]; then
    LIST="${LIST} listener"
fi

for item in ${LIST}; do
    IMAGE="${REGISTRY}/testpmd-container-app-${item}:${TAG}"
    $CLI build ${item} -f ${item}/Dockerfile -t $IMAGE $EXTRA
    $CLI push $IMAGE
done
