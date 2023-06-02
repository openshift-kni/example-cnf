#!/bin/bash

set -e

if [ $# != 2 ]; then
    echo "Usage: $0 <output file> <extra tag>" 1>&2
    exit 1
fi

VERSIONS="$1"
EXTRA="$2"

DIRS="testpmd-container-app trex-container-app cnf-app-mac-operator testpmd-lb-operator testpmd-operator trex-operator nfv-example-cnf-index"

FILES="$(git diff --name-only -r origin/${GITHUB_BASE_REF:-main}:)"

echo "declare -A VERSIONS" > "$VERSIONS"

count=0
for d in $DIRS; do
    vers="$(cd "$d" || exit 1; make -s version)"
    if [ "$FORCE" == true ] || grep -q "$d/" <<< "$FILES"; then
        echo "VERSIONS[$d]=$vers-$EXTRA" >> "$VERSIONS"
        echo "$d"
        count=$((count + 1))
    else
        echo "VERSIONS[$d]=$vers" >> "$VERSIONS"
        # Force nfv-example-cnf-index to be displayed if at least one
        # change to the subdirs has been detected. This will force the
        # index to be generated.
        if [ "$d" == nfv-example-cnf-index ] && [ "$count" -gt 0 ]; then
            echo "$d"
        fi
    fi
done

# generate-versions.sh ends here
