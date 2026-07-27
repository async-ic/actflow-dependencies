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

# deps: 002 license dir; host gcc (pre-007) | used by: 006-bison, 072-xyce (find_package FLEX>=2.6)

# builds flex into $ACT_HOME (first on PATH) so cmake's find_package(FLEX) uses it
# - xyce 7.10 needs flex >=2.6, the centos7 host ships 2.5.37. built before gcc16
# with the host compiler (old C tripped by gcc16 C23 defaults) and build-only, so
# 021 trims it. git checkout ships no configure: ./autogen.sh generates it.

echo
echo "#### flex ####"
echo
cd $EDA_SRC/org-westes-flex
cp COPYING $ACT_HOME/license/LICENSE_org-westes-flex
./autogen.sh || exit 1
./configure --prefix=$ACT_HOME || exit 1
make -j || exit 1
make install || exit 1
