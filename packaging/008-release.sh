#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ole Richter - Technical University of Denmark
#
# Publishes one arch variant into the release of version $1, called once per arch by
# an independent CI job: the release is get-or-created (title/description + sources
# link) and each job then only appends its own asset links. So a late or failing arch
# never holds back the others, and it can still join the release afterwards.
# Links are added only for packages present in the registry and skipped when already
# linked, which makes the job re-runnable.
# usage: 008-release.sh <version> [arch_level]
set -u

VERSION="${1:-}"
ARCH_LEVEL="${2:-}"
[ -n "$VERSION" ] || { echo "release: no version given" >&2; exit 1; }

API="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}"
PKG_BASE="${API}/packages/generic/actflow-dependencies/${VERSION}"

HDR="JOB-TOKEN: ${CI_JOB_TOKEN}"

BODY=$(mktemp)
trap 'rm -f "$BODY"' EXIT

# request helper: prints the HTTP status, leaves the response body in $BODY
api() { # method url [json]
  if [ $# -ge 3 ]; then
    curl -s -o "$BODY" -w '%{http_code}' --request "$1" --header "$HDR" \
      --header 'Content-Type: application/json' --data "$3" "$2"
  else
    curl -s -o "$BODY" -w '%{http_code}' --request "$1" --header "$HDR" "$2"
  fi
}

# create the release unless it already exists; a concurrent job winning the create
# is not an error, the existence re-check below decides.
ensure_release() {
  code=$(api GET "${API}/releases/${VERSION}")
  case "$code" in 2*) echo "release ${VERSION} exists"; return 0 ;; esac

  payload=$(jq -n \
    --arg tag "$VERSION" \
    --arg ref "${CI_COMMIT_SHA}" \
    --arg name "$(head -n 1 packaging/release_titel.md)" \
    --arg desc "$(head -n 1 packaging/release_description.md)" \
    --arg lname "actflow_dependencies_sources.tar.gz" \
    --arg lurl "${PKG_BASE}/actflow_dependencies_sources.tar.gz" \
    '{tag_name:$tag, ref:$ref, name:$name, description:$desc,
      assets:{links:[{name:$lname, url:$lurl}]}}')

  code=$(api POST "${API}/releases" "$payload")
  case "$code" in 2*) echo "created release ${VERSION}"; return 0 ;; esac

  code=$(api GET "${API}/releases/${VERSION}")
  case "$code" in 2*) echo "release ${VERSION} created concurrently"; return 0 ;; esac
  echo "release: create failed -> HTTP $code: $(cat "$BODY")" >&2
  return 1
}

# --head (not --request HEAD, which waits for a body); --location as the registry may
# redirect the download to object storage
pkg_status() { # url
  curl -s -o /dev/null -w '%{http_code}' --head --location --header "$HDR" "$1"
}

# link one registry package to the release, skipping what was never uploaded
add_link() { # file_name
  url="${PKG_BASE}/$1"
  code=$(pkg_status "$url")
  if [ "$code" = "404" ]; then
    echo "  skip $1 (not in the registry)"
    return 0
  fi

  code=$(api GET "${API}/releases/${VERSION}")
  if jq -e --arg n "$1" 'any(.assets.links[]?; .name == $n)' "$BODY" >/dev/null 2>&1; then
    echo "  $1 already linked"
    return 0
  fi

  payload=$(jq -n --arg name "$1" --arg url "$url" '{name:$name, url:$url}')
  code=$(api POST "${API}/releases/${VERSION}/assets/links" "$payload")
  case "$code" in
  2*) echo "  linked $1" ;;
  *) echo "release: linking $1 failed -> HTTP $code: $(cat "$BODY")" >&2; return 1 ;;
  esac
}

ensure_release || exit 1

[ -n "$ARCH_LEVEL" ] || exit 0
add_link "actflow_dependencies_package_${ARCH_LEVEL}.tar.gz" || exit 1
add_link "actflow_dependencies_testing_package_${ARCH_LEVEL}.tar.gz" || exit 1
