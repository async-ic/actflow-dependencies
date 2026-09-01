#!/bin/bash

#
# Copyright 2026, 2022 Ole Richter - Technical University of Denmark, University of Groningen

#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -eo pipefail

echo
echo "#### package the repository sources ####"
echo

# packaging and suppling the sources with working build scripts is required by multiple strong copyleft licenses

if [ -d "../packaging" ]; then echo "please exec from repository root (one folder up)"; exit 1; fi

RETRY_WAIT="${ACTFLOW_REGISTRY_RETRY_WAIT:-10}"

# runs a download up to 3 times; upstream mirrors drop connections mid-transfer
# (curl "HTTP/2 stream 0 was not closed cleanly: PROTOCOL_ERROR"), which curl
# --retry does not cover as it is not a transient HTTP status
retry() { # command...
  attempt=1
  until "$@"; do
    [ "$attempt" -lt 3 ] || { echo "download failed after $attempt attempts" >&2; return 1; }
    echo "download failed, retrying in ${RETRY_WAIT}s" >&2
    sleep "$RETRY_WAIT"
    attempt=$((attempt + 1))
  done
}

# single version string shared by every pipeline job. A tag publishes
# under the tag, else YYYY-MM-DD_hash.
VERSION="${CI_COMMIT_TAG:-}"
# date from the commit, not job runtime, so reruns/day-rollover never drift the version
[ -n "$VERSION" ] || VERSION="$(git show -s --format=%cd --date=short HEAD 2>/dev/null || date '+%Y-%m-%d')_${CI_COMMIT_SHORT_SHA:-local}"
# line 1 is the release version (all readers take only the first line); the remaining
# lines are a "<path> <tag | shorthash (branch) | shorthash>" component manifest.
echo "$VERSION" > actflow_dep.version
# append each submodule's pinned version: exact tag, else short sha + .gitmodules
# branch, else short sha. skipped when packing outside a checkout.
if [ -f .gitmodules ] && git rev-parse --git-dir >/dev/null 2>&1; then
  git submodule --quiet foreach '
    sha=$(git rev-parse --short HEAD)
    # CI-safe: shallow submodule clones carry no tag/branch refs; if HEAD is not on an
    # exact tag locally, shallow-fetch the ref(s) pointing at it, then retry describe.
    if ! git describe --tags --exact-match >/dev/null 2>&1; then
      full=$(git rev-parse HEAD)
      for r in $(git ls-remote --tags --heads origin 2>/dev/null | grep "^$full" | cut -f2 | sed "s/\\^{}\$//" | sort -u); do
        git fetch -q --depth 1 origin "$r:$r" 2>/dev/null || true
      done
    fi
    if v=$(git describe --tags --exact-match 2>/dev/null); then :
    elif br=$(git -C "$toplevel" config -f .gitmodules "submodule.$sm_path.branch" 2>/dev/null); then v="$sha ($br)"
    else v="$sha"; fi
    printf "%s %s\n" "$sm_path" "$v"
  ' >> actflow_dep.version
fi
# gmp/mpfr/mpc for gcc's in-tree build (statically linked into cc1plus): fetch into the
# gcc srcdir now so they are captured in the source bundle (copyleft: the shipped compiler
# links them) and the offline build stage needs no network. --no-isl: Graphite unused.
( cd src/org-gnu-gcc && retry ./contrib/download_prerequisites --no-isl )

# pipe not tar -I: centos7 tar 1.26 passes "gzip -9" as one exec name and fails
tar --exclude-vcs --exclude='./actflow_dependencies_sources_*.tar.gz' -cf - ./* | gzip -9 > "actflow_dependencies_sources_${VERSION}.tar.gz"
ls -lh "actflow_dependencies_sources_${VERSION}.tar.gz"

