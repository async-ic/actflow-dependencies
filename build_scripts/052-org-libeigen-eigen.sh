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

# deps: 005-cmake, 050-fftw | used by: 060-trilinos (EIGEN3_ROOT)

echo "#############################"
echo "# eigen"

cd $EDA_SRC/org-libeigen-eigen
cp COPYING.README $ACT_HOME/license/LICENSE_org-libeigen-eigen
cat COPYING.* >> $ACT_HOME/license/LICENSE_org-libeigen-eigen
if [ ! -d build ]; then
	mkdir build
fi
cd $EDA_SRC/org-libeigen-eigen/build
cmake \
-D CMAKE_INSTALL_PREFIX=$ACT_HOME \
-D CMAKE_INSTALL_LIBDIR=lib \
-D CMAKE_LIBRARY_PATH=$ACT_HOME/lib \
-D CMAKE_INCLUDE_PATH=$ACT_HOME/include \
-D CMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
-D CMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
-D CMAKE_POSITION_INDEPENDENT_CODE=ON \
-D CMAKE_BUILD_TYPE=Release \
-D FFTW_LIBRARIES=$ACT_HOME/lib \
.. || exit 1
make -j4 || exit 1
make install || exit 1
 
 ln -s $ACT_HOME/include/eigen3/Eigen $ACT_HOME/include/Eigen