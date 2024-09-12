# Docker apt-cacher-ng
[apt-cacher-ng](https://www.unix-ag.uni-kl.de/~bloch/acng/) in a Docker
container with configurable geolocation to allow selection of the
closest/fastest mirrors.

*   [Usage](#usage)
    +   [Environment](#environment)
    +   [Volumes](#volumes)
*   [Mirror Lists](#mirror-lists)
*   [Countries](#countries)
*   [Links](#links)

## Usage
As a bare minimum the `TZ` environment variable should be set, to provide some
information about sources to choose.

```
docker run -d \
  --name apt-cacher-ng \
  -p 3142:3142 \
  -e TZ="<timezone>" \
  -v apt-cacher-ng_cache:/var/cache/apt-cacher-ng \
  -v apt-cacher-ng_lists:/usr/lib/apt-cacher-ng \
  moonbuggy2000/apt-cacher-ng:latest
```

Other environment variables can be set for finer control, directly specifying
the [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) code
to use globally or per-distribution.

In the event that a particular distribution has no servers in the specified
country it will default to the full sources list.

### Environment
*   `TZ`              - set the timezone (default: `Etc/UTC`)
*   `COUNTRY`         - ISO code for default country to use for repos (default: set from _TZ_)
*   `ALPINE_COUNTRY`  - ISO code for country to use for Alpine repos (default: _COUNTRY_)
*   `ARMBIAN_COUNTRY` - ISO code for country to use for Armbian repos (default: _COUNTRY_)
*   `DEBIAN_COUNTRY`  - ISO code for country to use for Debian repos (default: _COUNTRY_)
*   `LIST_EXPIRY`     - number of days before refreshing repo lists (default: `30`)
*   `ACNG_SSL_PASSTHROUGH`  - enable SSL passthrough (default: `true`)
*   `ACNG_FOLLOW_LOG`       - follow _apt-cacher.log_ on stdout (default: `false`)
*   `ACNG_FOLLOW_ERROR`     - follow _apt-cacher.err_ on stdout (default: `false`)
*   `DEBUG`           - extra output from the update scripts

### Volumes
The following are persisted by the Dockerfile:

*   `/usr/lib/apt-cacher-ng`    - repository data
*   `/var/cache/apt-cacher-ng`  - cache directory

Optionally, the scripts directory can be persisted if scripts are modified or
added:

*   `/scripts`  - scripts path

## Mirror Lists
Mirror lists are pulled from the web and parsed by the _update-*.sh_ scripts in
_/scripts_.

Although all distributions in _/etc/apt-cacher-ng/acng.conf_ will work in the
normal way, only those with existing scripts will be automatically updated and
allow selection of a preferred country.

At this stage I've only created scripts for the distributions I can use a cache
for, but it shouldn't be hard to use these existing scripts as a template to add
more distributions as desired.

It's also necessary to add any new scripts to _/etc/s6-overlay/s6-rc.d/acng-init/up_,
which makes the necessary additions/modifications to _acng.conf_ at startup.

The container overwrites _/etc/apt-cacher-ng/acng.conf_ with
_/etc/apt-cacher-ng/acng-initial.conf_ during init, so to make manual changes
directly to _acng.conf_ the _acng-initial.conf_ file should be persisted and any
modifications made there.

## Countries
The `<distro>_COUNTRY` environment variables are optional, allowing an override
of the global default (`COUNTRY`) in the case that a particular distribution
doesn't have mirrors in the default country but does have some in another
country that are fast enough to prefer.

If a distribution has no mirrors in the global `COUNTRY` and `<distro>_COUNTRY`
isn't set, the full global mirror list will be used. This means that things
should always work, falling back to an indiscriminate source selection without
consideration of location.

#### `/scripts/iso3166.csv`
The [iso3166.csv](root/scripts/iso3166.csv) file is used to match strings pulled from
the list data we're parsing. However, not all the sources use the official
country name, and in some cases we need to deal with state or city names, so
there's some custom strings added at the bottom of the file.

## Links
GitHub: <https://github.com/moonbuggy/docker-apt-cacher-ng>

Docker Hub: <https://hub.docker.com/r/moonbuggy2000/apt-cacher-ng>
