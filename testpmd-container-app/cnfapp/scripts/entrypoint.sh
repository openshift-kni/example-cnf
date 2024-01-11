#!/bin/bash

set -ex

# Start lifecycle webserver in background
python3 /usr/local/bin/webserver &

# Call to testpmd/run
/bin/bash /var/lib/testpmd/run
