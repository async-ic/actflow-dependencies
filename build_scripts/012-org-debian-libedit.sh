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

# deps: 010-ncurses | used by: downstream ACT interactive tools (runtime)

echo "#############################"
echo "# libedit"
cd "$EDA_SRC/org-debian-libedit"
# use the shipped configure, not autoreconf: configure.ac needs AC_CHECK_INCLUDES_DEFAULT
# (autoconf 2.70+), the host has 2.69, so regenerating produces a broken configure.
# git checkout drops mtimes, so make would try to re-run the (absent) automake-1.18 to
# refresh Makefile.in; touch the generated files newer than their sources so they look current.
find . \( -name "*.in" -o -name configure -o -name aclocal.m4 \) -exec touch {} +
# --disable-examples: not shipped, saves build time/space (the library itself is unaffected)
./configure --prefix $ACT_HOME --disable-examples LIBS="-L$ACT_HOME/lib ${LIBS}" CPPFLAGS="-I$ACT_HOME/include -I$ACT_HOME/include/ncurses ${CPPFLAGS}" LDFLAGS="-L$ACT_HOME/lib ${LDFLAGS} -Wl,-rpath=\\\$\$ORIGIN/../lib"  || exit 1
make -j || exit 1
make install || exit 1
cp COPYING $ACT_HOME/license/LICENSE_libedit.txt
