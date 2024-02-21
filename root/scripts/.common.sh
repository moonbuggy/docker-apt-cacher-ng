#! /bin/bash
# shellcheck disable=SC2034

ISO_CSV="iso3166.csv"

# [ ! ${LISTS_PATH+set} ] && LISTS_PATH='../usr/lib/apt-cacher-ng'
[ ! ${LISTS_PATH+set} ] && LISTS_PATH='/usr/lib/apt-cacher-ng'
mkdir -p "${LISTS_PATH}"

# days before we'll re-download the raw list
LIST_EXPIRY="${LIST_EXPIRY:-30}"

## get_country_code <COUNTRY>
#
# match a string against a CSV list of ISO3155 alpha-2 country codes
#
get_country_code () {
  local country && country="${*}"

  # trim at slash, so we can accept TZ '<country>/<city>' strings
  country="${country%%/*}"

  [ x"${country}" = x"" ] \
    && >&2 echo "ERROR: No country: ${country}" \
    && return 1

  if ! country_code="$(grep -iP "^${country},[A-Z]{2}$" "${ISO_CSV}")"; then
    >&2 printf '\nNOTICE: No country code for: %s\n' "${country}"
    return 1
  fi

  echo "${country_code##*,}"
  return 0
}

## get_list <FILENAME> <URL> (<CUT_BEFORE>)
#
# CUT_BEFORE is a regex and any text before the first instance of a matching
# string will be trimmed from the file. This makes the raw list processing
# slightly quicker, since we won't feed it <head> (for example) and other elements
# at the top of the HTML we don't need.
#
get_list() {
  local list_file && list_file="${1}"
  local list_url && list_url="${2}"
  local cut_before && cut_before="${3}"

  [ ${DEBUG+set} ] && >&2 echo "get_list(${*})"

  # we can't pipe wget directly into sed because we want to get an exit code
  # from wget. there's no point running the data parsing if we can't pull
  # fresh data.
  # [ ! -z "${cut_before}" ] \
  #   && wget -qO- "${list_url}" | sed "/${cut_before}/,\$!d" >"${list_file}" \
  #   || wget -qO- "${list_url}" >"${list_file}"

  local list_content
  list_content="$(wget -qO- "${list_url}")"

  [ $? -ne 0 ] \
    && echo "ERROR: failed to download '${list_url}'" \
    && return 1

  [ ! -z "${cut_before}" ] \
    && echo "${list_content}" | sed "/${cut_before}/,\$!d" >"${list_file}" \
    || echo "${list_content}" >"${list_file}"
}

## update_list <FILENAME> <URL> (<LIST_EXPIRY>)
#
# if FILENAME doesn't exist, download it from URL
#
# if FILENAME does exist, if it was modified more than LIST_EXPIRY days ago then
# download it from URL
#
# return 1 if FILENAME isn't downloaded
#
update_list() {
  local list_file && list_file="${1}"
  local list_url && list_url="${2}"
  local list_expiry && list_expiry="${3:-${LIST_EXPIRY}}"
  local cut_before && cut_before="${4}"

  [ ${DEBUG+set} ] && >&2 echo "update_list(${*})"

  if [ ! -f "${list_file}" ]; then
    echo "${list_file} doesn't exist.. downloading"
    get_list "${list_file}" "${list_url}" "${cut_before}" || return 1
  fi

  list_modified="$(stat ${list_file} | grep -oP '(?<=Modify:\s).*(?=\.)')"
  list_age=$((($(date +%s) - $(date -d "${list_modified}" +%s)) / 86400))

  printf "%s: %d day(s) old, expiry: ${list_expiry}.. " "${list_file}" "${list_age}"

  if [ ${list_expiry} -gt ${list_age} ]; then
    echo 'skipping download'
    return 1
  else
    get_list "${list_file}" "${list_url}" "${cut_before}" || return 1
    echo 'downloaded'
    return 0
  fi
}

COMMON_SOURCED=1
