#! /bin/bash

cd "${0%/*}/" || ( echo "ERROR: no folder at ${0%/*}/"; exit )

# this just lets us use the get_country_code() function in .common.sh as
# an executable inside s6-rc.d
[ ! ${COMMON_SOURCED+set} ] && . .common.sh

get_country_code "${*}"
