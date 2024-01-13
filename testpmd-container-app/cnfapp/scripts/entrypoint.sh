#!/bin/bash

set -ex

# Start lifecycle webserver in background
go run /usr/local/bin/webserver.go &

# Call to testpmd/run
/bin/bash /var/lib/testpmd/run
