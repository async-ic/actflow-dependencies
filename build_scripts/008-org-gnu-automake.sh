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

# builds automake 1.17 into $ACT_HOME (first on PATH) for deps needing a newer
# automake than the host 1.13 - mpich v5.0.1 autogen leaves PAC_SUBCFG macros
# unexpanded under 1.13. bootstrap generates the missing configure. build-only,
# trimmed by 021.

echo "#############################"
echo "# automake"
cd $EDA_SRC/org-gnu-automake
cp COPYING $ACT_HOME/license/LICENSE_org-gnu-automake
./bootstrap || exit 1
./configure --prefix=$ACT_HOME || exit 1
make -j || exit 1
make install || exit 1
# also search the system aclocal dir for host m4 macros (libtool, pkg-config),
# else deps regenerating their build system fail "LIBTOOL is undefined".
echo /usr/share/aclocal > $ACT_HOME/share/aclocal/dirlist
