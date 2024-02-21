#! /bin/bash
# shellcheck source=/dev/null

cd "${0%/*}/" || ( echo "ERROR: no folder at ${0%/*}/"; exit )

[ ! ${COMMON_SOURCED+set} ] && . .common.sh

for file in update-*.sh; do
  printf 'Running %s..\n' "${file}"
  "./${file}"
  printf '\n'
done
