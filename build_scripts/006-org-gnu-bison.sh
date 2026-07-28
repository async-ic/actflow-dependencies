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

# deps: 004-flex; host gcc (pre-007) | used by: 072-xyce (find_package BISON>=3.3)

# builds bison into $ACT_HOME (first on PATH) so find_package(BISON) uses it: xyce 7.10
# needs bison >=3.3, centos7 host ships 3.0.4. build-only, 021 trims it. after 004-flex:
# bison's scanner needs flex >=2.6. bison <=3.7.6 keeps AC_PREREQ 2.68 (host autoconf 2.69
# ok); 3.8+ needs 2.71. bootstrap flags:
# --no-git --gnulib-srcdir: git checkout ships no configure; bootstrap generates it from
#   the bundled gnulib snapshot. sources are packed --exclude-vcs (no .git), so without
#   --no-git bootstrap's git discovery escapes to the superproject's uninitialized
#   submodules -> "some git submodules are not initialized" die.
# --skip-po: no translation fetch (offline build, avoids a po-server 404).
# -std=gnu11: bison's gnulib (2021) won't compile under gcc16's C23 default; pin C11.

echo
echo "#### bison ####"
echo
cd $EDA_SRC/org-gnu-bison
cp COPYING $ACT_HOME/license/LICENSE_org-gnu-bison
./bootstrap --skip-po --no-git --gnulib-srcdir="$EDA_SRC/org-gnu-bison/gnulib" || exit 1
./configure --prefix=$ACT_HOME CFLAGS="-std=gnu11 ${CFLAGS}" || exit 1
make -j || exit 1
make install || exit 1
