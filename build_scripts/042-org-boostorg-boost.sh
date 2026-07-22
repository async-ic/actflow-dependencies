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

echo 
echo "#### Boost ####"
echo
cd $EDA_SRC/org-boostorg-boost
cp LICENSE_1_0.txt $ACT_HOME/license/LICENSE_org-boostorg-boost
# currently building without MPI (MPICH)
echo "using mpi ;" >> user-config.jam
./bootstrap.sh --prefix=$ACT_HOME --without-libraries=python || exit 1
echo "using mpi ;" >> project-config.jam
echo "## building ##"
# lzma compression is disabled in iostreams because the ABI symbol patch of lzma is not functioning and was to much work to debug
./b2 -j2 hardcode-dll-paths=true dll-path="'\$ORIGIN/../lib'" -s NO_LZMA=1 -s NO_BZIP2=1  install || exit 1
