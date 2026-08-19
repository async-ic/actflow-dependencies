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

# deps: host automake>=1.11/perl/m4>=1.4.16 | used by: 003-automake, 006-bison

# builds autoconf 2.72 into $ACT_HOME, precede 003-automake and 006-bison.

echo
echo "#### autoconf ####"
echo
cd $EDA_SRC/org-gnu-autoconf
cp COPYING* $ACT_HOME/license/LICENSE_org-gnu-autoconf 2>/dev/null
# packed --exclude-vcs: no .git, so git-version-gen would yield UNKNOWN; freeze the version
# from NEWS into .tarball-version. bootstrap then regenerates the missing configure.
sed -n 's/^\* Noteworthy changes in release \([0-9][0-9.]*\).*/\1/p' NEWS | head -1 > .tarball-version
./bootstrap || exit 1
./configure --prefix=$ACT_HOME || exit 1
make -j || exit 1
make install || exit 1
