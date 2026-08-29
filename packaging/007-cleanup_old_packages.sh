#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ole Richter - Technical University of Denmark
#
# Retention for the generic 'actflow-dependencies' package registry: keep the 3
# newest dated (YYYY-MM-DD_hash) versions, thin older ones to the oldest per 60-day
# window. Tagged releases (any non-dated version) and the
# just-published $1 are always kept.
# Needs an api-scoped token in $CLEANUP_API_TOKEN.

set -u
KEEP_RECENT=3
THIN_SECONDS=$((60 * 86400))
INCOMPLETE_SECONDS=$((2 * 86400))          # grace for a source-only build to finish
KEEP_VERSION="${1:-}"                       # version just published, never deleted
API="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}"
PKG_NAME="actflow-dependencies"

if [ -z "${CLEANUP_API_TOKEN:-}" ]; then
  echo "cleanup skipped: CLEANUP_API_TOKEN unset (CI_JOB_TOKEN cannot delete packages)"; exit 0
fi
if ! command -v jq >/dev/null || ! date -d "2000-01-01T00:00:00Z" +%s >/dev/null 2>&1; then
  echo "cleanup skipped: jq or GNU date unavailable"; exit 0
fi
HDR="PRIVATE-TOKEN: ${CLEANUP_API_TOKEN}"

# DELETE reporting the HTTP status+body on failure; -f hides why a delete is refused
# (403 = token lacks 'api' scope or Maintainer role, 404 = wrong id/endpoint).
DEL_BODY=$(mktemp)
trap 'rm -f "$DEL_BODY"' EXIT
api_delete() {
  code=$(curl -s -o "$DEL_BODY" -w '%{http_code}' --request DELETE --header "$HDR" "$1")
  case "$code" in 2*) return 0 ;; esac
  echo "  warn: DELETE $1 -> HTTP $code: $(cat "$DEL_BODY")"
  return 1
}

# dated (YYYY-MM-DD_hash) versions only, newest first, as "created_at id version"
# lines; the grep drops tagged releases so retention never deletes them
versions=$(
  page=1
  while :; do
    resp=$(curl -sf --header "$HDR" \
      "$API/packages?package_type=generic&package_name=$PKG_NAME&per_page=100&page=$page&order_by=created_at&sort=desc") || break
    n=$(printf '%s' "$resp" | jq 'length')
    [ "$n" -eq 0 ] && break
    printf '%s' "$resp" | jq -r '.[] | "\(.created_at) \(.id) \(.version)"'
    [ "$n" -lt 100 ] && break
    page=$((page + 1))
  done | grep -E ' [0-9]{4}-[0-9]{2}-[0-9]{2}_' | sort -r
)

# drop incomplete packages: a build only becomes complete once a binary
# (actflow_dependencies_package_*) file is uploaded, so a version carrying just the
# source bundle is an abandoned/failed build. Deleted once past INCOMPLETE_SECONDS
# so in-flight pipelines are never touched.
now=$(date +%s)
printf '%s\n' "$versions" | while read -r created id version; do
  [ -n "$version" ] || continue
  [ "$version" = "$KEEP_VERSION" ] && continue
  [ $((now - $(date -d "$created" +%s))) -lt "$INCOMPLETE_SECONDS" ] && continue
  files=$(curl -sf --header "$HDR" "$API/packages/$id/package_files?per_page=100") || continue
  printf '%s' "$files" | jq -e 'any(.[]; .file_name | startswith("actflow_dependencies_package_"))' >/dev/null 2>&1 && continue
  echo "deleting incomplete (source-only) package: $version (id $id, $created)"
  api_delete "$API/packages/$id"
done

# keep the KEEP_RECENT newest, plus the oldest version in each fixed THIN_SECONDS
# window.
recent=$(printf '%s\n' "$versions" | head -n "$KEEP_RECENT" | awk '{print $3}')
last_bucket=""
while read -r created id version; do
  [ -n "$version" ] || continue
  [ "$version" = "$KEEP_VERSION" ] && continue
  printf '%s\n' "$recent" | grep -qxF "$version" && continue
  ts=$(date -d "$created" +%s)
  bucket=$((ts / THIN_SECONDS))
  if [ "$bucket" != "$last_bucket" ]; then last_bucket=$bucket; continue; fi
  echo "deleting old version: $version (id $id, $created)"
  api_delete "$API/packages/$id"
  curl -sf --request DELETE --header "$HDR" "$API/releases/$version" >/dev/null 2>&1 || true
  curl -sf --request DELETE --header "$HDR" "$API/repository/tags/$version" >/dev/null 2>&1 || true
done <<EOF
$(printf '%s\n' "$versions" | sort)
EOF
