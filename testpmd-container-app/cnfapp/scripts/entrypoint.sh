#!/bin/bash

set -ex

# Start lifecycle webserver in background
/usr/local/bin/webserver 8095 &

# Call to testpmd/run
/bin/bash /var/lib/testpmd/run
