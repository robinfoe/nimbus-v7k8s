#! /usr/bin/env bash

# usage run-testbed.sh RUBYSPEC

readonly RUBYSPEC="${1:-""}"

readonly RUNNAME="$(basename ${RUBYSPEC} .rb)"
readonly RESULTSDIR="results/$RUNNAME"

[[ -d "results/$RUNNAME" ]] && rm -rf "results/$RUNNAME"
mkdir -p "results/$RUNNAME"

# See https://confluence.eng.vmware.com/display/~jpeach/VMware+Product+Builds
readonly ESXBUILD=${ESXBUILD:-"ob-17168206"}
readonly VCBUILD=${VCBUILD:-"ob-17004997"}

declare -a EXTRA_NIMBUS_ARGS

# If the spec defines networks, then it means it wants an isolated
# testbed, so fix up the nimbus args accordingly.
if grep -q -e "network.*=>" "${RUBYSPEC}" ; then
    echo enabling isolated testbed
    EXTRA_NIMBUS_ARGS+="--isolated-testbed"
fi

# Fucking nimbus-gateway doesn't have realpath(1). We need to use absolute
# paths because path arguments are passed across nimbus commanda that expect
# them to be cross-mounted over NFS.
abs() {
    local target="$1"
    local p=$(cd $(dirname "$1") && pwd)
    echo "$p/$(basename "$1")"
}

/mts/git/bin/nimbus-testbeddeploy \
    --noStatsDump \
    --nimbusLocation sc,wdc \
    --customizeWorker "template=worker-centos8" \
    --testbedSpecRubyFile "$(abs "${RUBYSPEC}")" \
    --resultsDir "$(abs "${RESULTSDIR}")" \
    --runName "${RUNNAME}" \
    --esxBuild ${ESXBUILD} \
    --vcvaBuild ${VCBUILD} \
    ${EXTRA_NIMBUS_ARGS[@]}

find "${RESULTSDIR}" -name "*-result.json" | grep -v prepare
