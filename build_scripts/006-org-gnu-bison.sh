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

# builds bison into $ACT_HOME (first on PATH) so cmake's find_package(BISON) uses it
# - xyce 7.10 needs bison >=3.3, the centos7 host ships 3.0.4. build-only, so 021
# trims it. ordered after 004-flex: bison's own scanner needs the flex >=2.6 we just
# installed. git checkout ships no configure: ./bootstrap generates it (needs the
# nested gnulib submodule).
# bison <=3.7.6 keeps AC_PREREQ 2.68 (host autoconf 2.69 ok); 3.8+ needs 2.71.
# --skip-po: don't fetch translations (offline build, avoids a po-server 404).
# -std=gnu11: bison's gnulib (2021) won't compile under gcc16's C23 default (K&R /
# implicit-int); pin C11 so it builds whichever gcc is first on PATH.

echo
echo "#### bison ####"
echo
cd $EDA_SRC/org-gnu-bison
cp COPYING $ACT_HOME/license/LICENSE_org-gnu-bison
./bootstrap --skip-po || exit 1
./configure --prefix=$ACT_HOME CFLAGS="-std=gnu11 ${CFLAGS}" || exit 1
make -j || exit 1
make install || exit 1
