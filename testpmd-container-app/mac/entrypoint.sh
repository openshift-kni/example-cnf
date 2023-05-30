#!/bin/sh

set -ex

MAC_WORKAROUND_VERSION=${MAC_WORKAROUND_VERSION:="4.5"}
MAC_WORKAROUND_FILE=${MAC_WORKAROUND_FILE:="sriov"}

cp -f "/sriov-${MAC_WORKAROUND_VERSION}" "/hostbin/${MAC_WORKAROUND_FILE}"
echo "Entering sleep... (success)"

# Sleep forever.
# sleep infinity is not available in alpine; instead lets go sleep for ~68 years. Hopefully that's enough sleep
sleep 2147483647
