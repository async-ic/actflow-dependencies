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

# deps: 005-cmake; builds only AMD (xyce cmake/trilinos/AMD) | used by: 060-trilinos (TPL_ENABLE_AMD)

echo "#############################"
echo "# suitesparse"
cd $EDA_SRC/tamu-drtimothyaldendavis-suitesparse
# license
cp LICENSE.txt $ACT_HOME/license/LICENSE_tamu-drtimothyaldendavis-suitesparse

cmake \
 -D SuiteSparsePath=$EDA_SRC/tamu-drtimothyaldendavis-suitesparse \
 -D CMAKE_INSTALL_PREFIX=$ACT_HOME \
-D CMAKE_INSTALL_LIBDIR=lib \
 -D CMAKE_BUILD_TYPE=Release \
 -D CMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
 -D CMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
 -D CMAKE_POSITION_INDEPENDENT_CODE=ON \
 $EDA_SRC/sandia-xyce-xyce/cmake/trilinos/AMD  || exit 1
cmake --build . -t install  || exit 1

