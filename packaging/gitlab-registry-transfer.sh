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
#   down <published-name> <local-file>   download (needs curl or wget; the CI before_script installs one)
set -eu

VERSION="${ACTFLOW_DEP_VERSION:-}"
[ -n "$VERSION" ] || VERSION="$(cat actflow_dep.version 2>/dev/null || true)"
[ -n "$VERSION" ] || { echo "registry: no version (ACTFLOW_DEP_VERSION unset and actflow_dep.version missing)" >&2; exit 1; }
BASE_URL="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/actflow-dependencies/${VERSION}"

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
    command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || \
      { echo "registry: need curl or wget (install it in the CI before_script)" >&2; exit 1; }
    fetch "${BASE_URL}/$2" "$3"
    echo "downloaded ${BASE_URL}/$2 -> $3" ;;
  *) echo "usage: $0 up <file> <name> | down <name> <file>" >&2; exit 1 ;;
esac
