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

echo 
echo "#### package the repository sources ####"
echo

# packaging and suppling the sources with working build scripts is required by multiple strong copyleft licenses
# that we need to comply to

if [ -d "../packaging" ]; then echo "please exec from repository root (one folder up)"; exit 1; fi

# single version string shared by every pipeline job (the registry key the sources
# and binaries are up-/downloaded under, and the release/git tag). Minted once here,
# so a build spanning midnight cannot desync jobs on $(date). A tag pipeline publishes
# under the tag, else YYYY-MM-DD_hash.
VERSION="${CI_COMMIT_TAG:-}"
[ -n "$VERSION" ] || VERSION="$(date '+%Y-%m-%d')_${CI_COMMIT_SHORT_SHA:-local}"
echo "$VERSION" > actflow_dep.version
tar --exclude-vcs -I 'gzip -9' \
-cf "actflow_dependencies_sources_${VERSION}.tar.gz" ./*
ls -lh "actflow_dependencies_sources_${VERSION}.tar.gz"

