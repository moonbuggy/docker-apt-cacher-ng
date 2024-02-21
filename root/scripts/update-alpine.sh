#! /bin/bash

DISTRO_NAME='alpine'
LIST_URL='https://mirrors.alpinelinux.org/'

cd "${0%/*}/" || ( echo "ERROR: no folder at ${0%/*}/"; exit )

[ ! ${COMMON_SOURCED+set} ] && . .common.sh
LIST_FILE="${LISTS_PATH}/list_${DISTRO_NAME}"

# don't fetch a new list from the web in a dry run
if [ ! ${DRY_RUN} ]; then
  # don't run update if the existing file is newer than LIST_EXPIRY
  update_list "${LIST_FILE}" "${LIST_URL}" "${LIST_EXPIRY}"
  [ $? -ne 0 ] && [ -f ${LISTS_PATH}/mirrors_${DISTRO_NAME} ] && exit
fi

# wipe existing output
rm -f ${LISTS_PATH}/backends_${DISTRO_NAME}* ${LISTS_PATH}/mirrors_${DISTRO_NAME}*

# one repo per line
[ ! ${DRY_RUN} ] && \
  echo "$(cat ${LIST_FILE} | xargs | \
    grep -oP '<tbody>.*<\/tbody>.*(?=pure-g\sstatus)' | \
    sed -En 's|\s*<\/(tr)>\s*|<\/\1>\n|gp')" \
  > ${LIST_FILE}

while read line; do
  # ignore empty lines
  [ ! -n "${line}" ] && continue

  url="$(echo "${line}" | grep -oP '(?<=href=)http:[^>]*' | sed -E 's|&#x2F;|\/|g')"

  # ignore lines without a URL
  [ ! -n "${url}" ] && continue

  country=$(echo "${line}" | grep -oP '(?<=<span>)[^<]*' | head -n1)
  country="${country##*, }"

  country_code="$(get_country_code ${country})"
  echo "${country} (${country_code}): ${url}"

  [ "${url:0-1}" != "/" ] && url="${url}/"
  echo "${url}" >> "${LISTS_PATH}/mirrors_${DISTRO_NAME}"

  # some repos don't have the country labelled, so we'll only add them to
  # the mirrors list, not a country-specific backend
  [ x"${country_code}" != x"" ] \
    && echo "${url}" >> "${LISTS_PATH}/backends_${DISTRO_NAME}.${country_code}"

  continue

done < "${LIST_FILE}"

echo "Done."
