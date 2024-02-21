#! /bin/bash

DISTRO_NAME='armbian'
LIST_URL='https://raw.githubusercontent.com/armbian/mirror/master/README.md'

cd "${0%/*}/" || ( echo "ERROR: no folder at ${0%/*}/"; exit )

[ ! ${COMMON_SOURCED+set} ] && . .common.sh
LIST_FILE="${LISTS_PATH}/list_${DISTRO_NAME}"

# don't fetch a new list from the web in a dry run
if [ ! ${DRY_RUN} ]; then
  # don't run update if the existing file is newer than LIST_EXPIRY
  update_list "${LIST_FILE}" "${LIST_URL}" "${LIST_EXPIRY}" '## Packages'
  [ $? -ne 0 ] && [ -f ${LISTS_PATH}/mirrors_${DISTRO_NAME} ] && exit
fi

# wipe existing output
rm -f ${LISTS_PATH}/backends_${DISTRO_NAME}* ${LISTS_PATH}/mirrors_${DISTRO_NAME}*

echo "http://apt.armbian.com/" >> "${LISTS_PATH}/mirrors_${DISTRO_NAME}"

unset find_urls

while read line; do
  # ignore short lines
  [ ${#line} -lt 5 ] && continue

  # if we hit a heading we need to start/stop looking for URLs as appropriate
  if [ "${line:0:2}" = '##' ]; then
    case "${line}" in
      *Packages*|*Archives*)
        find_urls=true
        ;;&
      *Packages*)
        printf '\nPackages\n'
        this_distro="${DISTRO_NAME}"
        continue
        ;;
      *Archive*)
        printf '\nArchive\n'
        this_distro="${DISTRO_NAME}_archive"
        continue
        ;;
      *)
        unset find_urls
        ;;
    esac
  fi

  # don't look for URLs unless we're in the right section of the code
  [ ! ${find_urls+set} ] && continue

  match=$(echo "${line}" | sed -En 's/^\|(http:[^\|]*).*\|(.*)\|$/\1 \2/gmp')
  [ ! -n "${match}" ] && continue

  url="${match%% *}"
  [ "${url:0-1}" != "/" ] && url="${url}/"

  country="${match#* }"
  country_code="$(get_country_code ${country})"

  echo "${country} (${country_code}): ${url}"

  echo "${url}" >> "${LISTS_PATH}/mirrors_${this_distro}"
  echo "${url}" >> "${LISTS_PATH}/backends_${this_distro}.${country_code}"
done < ${LIST_FILE}

echo "Done."
