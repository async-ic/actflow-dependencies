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

# snapshot of $ACT_HOME before tcl: everything installed so far (cmake, gcc,
# ncurses, zlib, libedit, readline) is build-only, so this records all files
# except shared objects (*.so, *.so.*) and license files.

echo "#############################"
echo "# list build-only files ($ACT_HOME so far, except *.so and license)"

cd $ACT_HOME
find . -type f ! -name "*.so" ! -name "*.so.*" ! -path "./license/*" ! -name "LICENSE.txt" \
	| sed 's|^\./||' | sort > build_only_files.list
