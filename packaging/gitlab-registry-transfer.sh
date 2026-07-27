#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ole Richter - Technical University of Denmark
#
# Moves the large sources / binary tarballs between CI jobs through the GitLab
# generic package registry instead of job artifacts, which exceed the size limit.
# The version key is the single string minted once in prepare (actflow_dep.version,
# propagated as the $ACTFLOW_DEP_VERSION dotenv var) so a build spanning midnight
# cannot desync jobs on $(date).
#   up   <local-file> <published-name>   upload   (needs curl; runs on build hosts)
#   down <published-name> <local-file>   download (curl or wget; ensures one on minimal test images)
set -eu

VERSION="${ACTFLOW_DEP_VERSION:-}"
[ -n "$VERSION" ] || VERSION="$(cat actflow_dep.version 2>/dev/null || true)"
[ -n "$VERSION" ] || { echo "registry: no version (ACTFLOW_DEP_VERSION unset and actflow_dep.version missing)" >&2; exit 1; }
BASE_URL="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/actflow-dependencies/${VERSION}"

# minimal/EOL test images (debian, ubuntu 16/18, ...) ship without curl or wget;
# install one, repointing apt at the archive mirrors the EOL releases were moved to.
ensure_downloader() {
  command -v curl >/dev/null 2>&1 && return 0
  command -v wget >/dev/null 2>&1 && return 0
  if command -v apt-get >/dev/null 2>&1; then
    sed -i -e 's|http://[a-z.]*archive.ubuntu.com|http://old-releases.ubuntu.com|g' \
           -e 's|http://security.ubuntu.com|http://old-releases.ubuntu.com|g' \
           -e 's|http://deb.debian.org|http://archive.debian.org|g' \
           -e 's|http://security.debian.org|http://archive.debian.org|g' /etc/apt/sources.list 2>/dev/null || true
    apt-get -o Acquire::Check-Valid-Until=false update -y || true
    apt-get install -y curl || apt-get install -y wget
  elif command -v dnf >/dev/null 2>&1; then dnf install -y curl
  elif command -v yum >/dev/null 2>&1; then yum install -y curl
  elif command -v zypper >/dev/null 2>&1; then zypper --non-interactive install -y curl
  elif command -v apk >/dev/null 2>&1; then apk add --no-cache curl
  fi
  command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1
}

fetch() { # url outfile
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --header "JOB-TOKEN: ${CI_JOB_TOKEN}" --output "$2" "$1"
  else
    wget --header="JOB-TOKEN: ${CI_JOB_TOKEN}" -O "$2" "$1"
  fi
}

case "${1:-}" in
  up)
    curl --fail --header "JOB-TOKEN: ${CI_JOB_TOKEN}" --upload-file "$2" "${BASE_URL}/$3"
    echo "uploaded $2 -> ${BASE_URL}/$3" ;;
  down)
    ensure_downloader || { echo "registry: no downloader available" >&2; exit 1; }
    fetch "${BASE_URL}/$2" "$3"
    echo "downloaded ${BASE_URL}/$2 -> $3" ;;
  *) echo "usage: $0 up <file> <name> | down <name> <file>" >&2; exit 1 ;;
esac
