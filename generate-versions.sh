#!/bin/bash

set -e

if [ $# != 2 ]; then
    echo "Usage: $0 <output file> <extra tag>" 1>&2
    exit 1
fi

VERSIONS="$1"
EXTRA="$2"

DIRS="testpmd-container-app trex-container-app cnf-app-mac-operator testpmd-operator trex-operator nfv-example-cnf-index"

FILES="$(git diff --name-only -r origin/${GITHUB_BASE_REF:-main}:|grep -Fv /.git || :)"

TESTPMD_APP=false
TREX_APP=false

echo "declare -A VERSIONS" > "$VERSIONS"

count=0
for d in $DIRS; do
    vers="$(cd "$d" || exit 1; make -s version)"
    # Force to build the operators if the corresponding app is built
    force=false
    case "$d" in
        testpmd-operator)
            if [ "$TESTPMD_APP" == true ]; then
                force=true
            fi
            ;;
        trex-operator)
            if [ "$TREX_APP" == true ]; then
                force=true
            fi
            ;;
    esac
    # Force nfv-example-cnf-index to be displayed if at least one
    # change to the subdirs has been detected. This will force the
    # index to be generated.
    if [ "$force" == true ] || [ "$FORCE_BUILD" == true ] || grep -q "$d/" <<< "$FILES" || { [ "$d" == nfv-example-cnf-index ] && [ "$count" -gt 0 ]; }; then
        echo "VERSIONS[$d]=$vers-$EXTRA" >> "$VERSIONS"
        echo "$d"
        count=$((count + 1))
        if [ "$d" == testpmd-container-app ]; then
            TESTPMD_APP=true
        fi
        if [ "$d" == trex-container-app ]; then
            TREX_APP=true
        fi
    else
        echo "VERSIONS[$d]=$vers" >> "$VERSIONS"
    fi
done

# generate-versions.sh ends here
