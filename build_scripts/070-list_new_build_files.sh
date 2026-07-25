#!/bin/bash

#
# Copyright 2026 Ole Richter - Technical University of Denmark
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

# snapshot of $ACT_HOME before xyce: adds files installed since
# 021-list_build_files.sh, except shared objects (*.so, *.so.*), binaries
# (bin/, e.g. tclsh, mpirun - may be needed at runtime by now), license files
# and entries already recorded. Together with 021, this is the full set of
# build-only files that can be stripped for a slimmed runtime-only package.

echo "#############################"
echo "# list new build-only files ($ACT_HOME, except *.so, bin/ and license)"

cd $ACT_HOME
find . -type f ! -path "./bin/*" ! -name "*.so" ! -name "*.so.*" ! -path "./lib/tcl*" ! -path "./license/*" ! -path "./share/info/*" ! -path "./share/terminfo/*" ! -path "./share/man/*" ! -name "LICENSE.txt" ! -name "build_only_files.list" \
	| sed 's|^\./||' >> build_only_files.list
sort -u -o build_only_files.list build_only_files.list
