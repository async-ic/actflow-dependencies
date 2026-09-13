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
# use the shipped configure, not autoreconf - could be reevaluated now that we ship a new autoconf.
find . \( -name "*.in" -o -name configure -o -name aclocal.m4 \) -exec touch {} +
# --disable-examples: not shipped, saves build time/space (the library itself is unaffected)
./configure --prefix $ACT_HOME --disable-examples LIBS="-L$ACT_HOME/lib ${LIBS}" CPPFLAGS="-I$ACT_HOME/include -I$ACT_HOME/include/ncurses ${CPPFLAGS}" LDFLAGS="-L$ACT_HOME/lib ${LDFLAGS}"  || exit 1
make -j$MAKE_JOBS || exit 1
make install || exit 1
cp COPYING $ACT_HOME/license/LICENSE_libedit.txt
