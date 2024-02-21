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

#ARG ACNG_PORT=3142
ARG LISTS_PATH="/usr/lib/apt-cacher-ng"
ARG SCRIPTS_PATH="/scripts"
ENV PUID="${PUID}" \
	PGID="${PGID}" \
	ACNG_SSL_PASSTHROUGH=1 \
	S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0

RUN add-contenv \
			S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
			LISTS_PATH=${LISTS_PATH} \
			SCRIPTS_PATH=${SCRIPTS_PATH} \
			PATH=${PATH}:${SCRIPTS_PATH}

VOLUME /var/cache/apt-cacher-ng /var/log/apt-cacher-ng "${LISTS_PATH}"

WORKDIR /scripts

#RUN LIST_EXPIRY=0 ./update.sh
#RUN ./update.sh

ENTRYPOINT ["/init"]

HEALTHCHECK --start-period=30s --timeout=10s CMD /healthcheck.sh
