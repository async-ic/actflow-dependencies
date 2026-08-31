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
echo "# libreadline"
cd $EDA_SRC/org-gnu-readline
cp COPYING $ACT_HOME/license/LICENSE_org-gnu-readline
# --with-shared-termcap-library: readline otherwise leaves UP/BC/PC/tgetent undefined in
# libreadline.so; pinned to -ltinfo, the termlib from 010-ncurses.
./configure --prefix=$ACT_HOME --with-shared-termcap-library=-ltinfo CPPFLAGS="-I$ACT_HOME/include ${CPPFLAGS}" LDFLAGS="-L$ACT_HOME/lib ${LDFLAGS} -Wl,-rpath=\\\$\$ORIGIN/../lib" || exit 1
make -j || exit 1
make install || exit 1
