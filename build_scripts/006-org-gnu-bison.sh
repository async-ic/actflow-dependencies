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

# deps: 002-autoconf, 004-flex; host gcc (pre-007) | used by: 072-xyce (find_package BISON>=3.3)

# builds bison into $ACT_HOME (first on PATH) so find_package(BISON) uses it: xyce 7.10
# needs bison >=3.3, centos7 host ships 3.0.4. build-only, 021 trims it. after 004-flex:
# bison's scanner needs flex >=2.6. 3.8+ needs AC_PREREQ 2.71 (host autoconf 2.69 too old);
# satisfied by 002-autoconf's 2.72 on PATH. bootstrap flags:
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
# packed --exclude-vcs: no .git; freeze bison's version from NEWS so git-version-gen
# doesn't yield UNKNOWN.
sed -n 's/^\* Noteworthy changes in release \([0-9][0-9.]*\).*/\1/p' NEWS | head -1 > .tarball-version
# bison symlinks m4/m4.m4 + data/m4sugar/*.m4 out of submodules/autoconf; its pinned commit
# can't be shallow-served (unadvertised SHA), so point it at the org-gnu-autoconf submodule
# (2.72, built by 002). relative link resolves submodules/ -> sibling src/org-gnu-autoconf.
rm -rf submodules/autoconf
ln -s ../../org-gnu-autoconf submodules/autoconf
./bootstrap --skip-po --no-git --gnulib-srcdir="$EDA_SRC/org-gnu-bison/gnulib" || exit 1
# --enable-relocatable: bison bakes $prefix/share/bison as its datadir; without this its
# relocate2() is a no-op (see gnulib relocatable.h) so the compiled-in CI build path is
# used verbatim and m4sugar.m4 is unfound once ACT_HOME moves. Enabled, it derives the
# datadir from the executable location at runtime (matches the bundle's $ORIGIN rpath).
./configure --prefix=$ACT_HOME --enable-relocatable CFLAGS="-std=gnu11 ${CFLAGS}" || exit 1
make -j || exit 1
make install || exit 1
