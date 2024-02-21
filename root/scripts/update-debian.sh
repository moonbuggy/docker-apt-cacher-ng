#! /bin/bash

DISTRO_NAME='debian'
LIST_URL='https://www.debian.org/mirror/list-full'

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

echo "http://deb.debian.org/debian/" >> "${LISTS_PATH}/mirrors_debian"

# one country per line
[ ! ${DRY_RUN} ] && \
  echo "$(cat ${LIST_FILE} | \
    tr -d '\n\t\r' | \
    grep -oP '<h3>.*(?=<h3>)' | \
    sed -En 's/(<h3>)/\n<h3>/gp')" \
    > ${LIST_FILE}

unset country_code
while read line; do
  # ignore empty lines
  [ ! -n "${line}" ] && continue

  match_country=$(echo "${line}" | sed -En 's|<h3><a name="([A-Z]{2})">([^<]*).*|\1 \2|p')
  if [ x"${match_country}" != x"" ]; then
    printf '\n'
    country_code="$(get_country_code "${match_country#* }")"
    printf '%s (%s)\n' "${match_country#* }" "${country_code}"
  fi

  urls=$(echo "${line}" | grep -oP 'http[^>]*debian/')
  [ ! -n "${urls[*]}" ] && continue

  for url in ${urls[*]}; do
    echo "${url}"
    echo "${url}" >> "${LISTS_PATH}/backends_${DISTRO_NAME}.${country_code}"
  done

  [ ! ${DRY_RUN} ] \
    && cat "${LISTS_PATH}/backends_${DISTRO_NAME}.${country_code}" \
      >> "${LISTS_PATH}/mirrors_${DISTRO_NAME}"

done < "${LIST_FILE}"

printf "\nDone.\n"
