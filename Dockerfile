# syntax = docker/dockerfile:1.4.0

ARG DEBIAN_RELEASE="bookworm"
ARG FROM_IMAGE="moonbuggy2000/debian-slim-s6:${DEBIAN_RELEASE}"

FROM "${FROM_IMAGE}"

RUN apt-get update \
	&& apt-get install -qy --no-install-recommends \
    apt-cacher-ng \
    ca-certificates \
		cron \
    wget \
  && rm -rf /var/lib/apt/lists/*

# sanity check before proceeding
ARG ACNG_VERSION=""
RUN installed_version="$(/usr/lib/apt-cacher-ng/acngtool cfgdump | sed -En 's|^UserAgent.*\/([0-9\.]*)|\1|p')" \
  && if [ "${installed_version}" != "${ACNG_VERSION}" ]; then \
      echo "ERROR: installed version (${installed_version}) doesn't match target version (${ACNG_VERSION})."; \
      exit 1; \
    fi

# get scripts and populate repo lists
COPY root/ /

# make a copy of the untouched config
ARG CONF_PATH="/etc/apt-cacher-ng"
RUN cp "${CONF_PATH}/acng.conf" "${CONF_PATH}/acng-initial.conf"

#ARG ACNG_PORT=3142
ARG LISTS_PATH="/usr/lib/apt-cacher-ng"
ARG SCRIPTS_PATH="/scripts"
ENV PUID="${PUID}" \
	PGID="${PGID}" \
	ACNG_SSL_PASSTHROUGH=1 \
	S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
	ACNG_PFILEPATTERNEX="(/dists/.*/by-hash/.*|\.tgz|\.tar|\.xz|\.zip|\.jar|\.ver|\.bz2|\.rpm|\.apk)$" \
	ACNG_VFILEPATTERNEX="(metalink\?repo=[0-9a-zA-Z-]+&arch=[0-9a-zA-Z_-]+|/\?release=[0-9]+&arch=|repodata/.*\.(xml|sqlite)\.(gz|bz2)|APKINDEX.tar.gz|filelists\.xml\.gz|filelists\.sqlite\.bz2|repomd\.xml|packages\.[a-zA-Z][a-zA-Z]\.gz)"

RUN add-contenv \
			S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
			CONF_PATH=${CONF_PATH} \
			LISTS_PATH=${LISTS_PATH} \
			SCRIPTS_PATH=${SCRIPTS_PATH} \
			PATH=${PATH}:${SCRIPTS_PATH}

VOLUME /var/cache/apt-cacher-ng /var/log/apt-cacher-ng "${LISTS_PATH}"

WORKDIR /scripts

#RUN LIST_EXPIRY=0 ./update.sh
#RUN ./update.sh

ENTRYPOINT ["/init"]

HEALTHCHECK --start-period=30s --timeout=10s CMD /healthcheck.sh
