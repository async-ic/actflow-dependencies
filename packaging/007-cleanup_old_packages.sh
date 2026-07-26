#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ole Richter - Technical University of Denmark
#
# Retention for the generic 'actflow-dependencies' package registry: keep the 5
# newest dated (YYYY-MM-DD_hash) versions, thin older ones to one per 60-day
# window, delete the rest (and each deleted version's release + git tag). Only
# dated versions are touched: tagged releases (any non-dated version) and the
# just-published $1 are always kept.
# Best-effort: needs an api-scoped token in $CLEANUP_API_TOKEN (CI_JOB_TOKEN
# cannot delete packages); a missing token or tools skips without failing the job.

set -u
KEEP_RECENT=5
THIN_SECONDS=$((60 * 86400))
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

# dated (YYYY-MM-DD_hash) versions only, newest first, as "created_at id version"
# lines; the grep drops tagged releases so retention never deletes them
versions=$(
  page=1
  while :; do
    resp=$(curl -sf --header "$HDR" \
      "$API/packages?package_type=generic&package_name=$PKG_NAME&per_page=100&page=$page&order_by=created_at&sort=desc") || break
    n=$(jq 'length' <<<"$resp")
    [ "$n" -eq 0 ] && break
    jq -r '.[] | "\(.created_at) \(.id) \(.version)"' <<<"$resp"
    [ "$n" -lt 100 ] && break
    page=$((page + 1))
  done | grep -E ' [0-9]{4}-[0-9]{2}-[0-9]{2}_' | sort -r
)

# keep the KEEP_RECENT newest; below that keep one per THIN_SECONDS. anchor tracks
# the last kept timestamp - a candidate survives only if it is that much older.
i=0; anchor=""
while read -r created id version; do
  [ -n "$version" ] || continue
  [ "$version" = "$KEEP_VERSION" ] && continue
  ts=$(date -d "$created" +%s)
  i=$((i + 1))
  if [ "$i" -le "$KEEP_RECENT" ]; then anchor=$ts; continue; fi
  if [ -n "$anchor" ] && [ $((anchor - ts)) -ge "$THIN_SECONDS" ]; then anchor=$ts; continue; fi
  echo "deleting old version: $version (id $id, $created)"
  curl -sf --request DELETE --header "$HDR" "$API/packages/$id" >/dev/null || echo "  warn: package $id delete failed"
  curl -sf --request DELETE --header "$HDR" "$API/releases/$version" >/dev/null 2>&1 || true
  curl -sf --request DELETE --header "$HDR" "$API/repository/tags/$version" >/dev/null 2>&1 || true
done <<EOF
$versions
EOF
