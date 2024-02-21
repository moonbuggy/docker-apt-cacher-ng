#! /bin/bash
# shellcheck shell=bash disable=SC2034

# This is an example of the script used to run the build hooks from
# the command line. All it really needs to know is '${DOCKER_REPO}'
# and the default tags to build. Optionally the tags to build when
# 'all' is given as an argument can be defined.

# Flags for build can also be hardcoded here if desired.
#NOOP=1
#DO_PUSH=1
#NO_BUILD=1

# define the target repo
DOCKER_REPO="${DOCKER_REPO:-moonbuggy2000/apt-cacher-ng}"

default_tag='latest'
all_tags='latest'

. "hooks/.build.sh"
