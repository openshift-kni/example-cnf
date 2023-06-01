#!/bin/bash

. ../versions.cfg

cat > "$1" <<EOF
# This file is used to define the list of operators and their versions
# that will be included in the index image via Makefile.
# The list of operators is used to obtain the corresponding bundle image
# and its digest to support disconnected environments.
OPERATORS=(
   trex-operator:v${VERSIONS[trex-operator]}
   testpmd-operator:v${VERSIONS[testpmd-operator]}
   testpmd-lb-operator:v${VERSIONS[testpmd-lb-operator]}
   cnf-app-mac-operator:v${VERSIONS[cnf-app-mac-operator]}
)
EOF

# generate-operators-cfg.sh ends here
