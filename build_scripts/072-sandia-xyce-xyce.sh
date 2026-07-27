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

# deps: 060-trilinos, 004-flex, 006-bison, 050-fftw, 030-mpich (wrappers) | used by: downstream actsim (grab_xyce.sh)

echo "#############################"
echo "# xyce"

cd $EDA_SRC/sandia-xyce-xyce

# license
cp COPYING $ACT_HOME/license/LICENSE_sandia-xyce-xyce

if [ ! -d build ]; then
	mkdir build
fi

echo "##########"
echo "building xyce"

cd $EDA_SRC/sandia-xyce-xyce/build

# build with the MPI wrappers: Trilinos (built with them) exports no explicit MPI
# lib (Trilinos_MPI_LIBRARIES=""), so a plain-g++ link leaves MPI_* undefined.
cmake \
-D CMAKE_INSTALL_PREFIX=$ACT_HOME \
-D CMAKE_C_COMPILER=mpicc \
-D CMAKE_CXX_COMPILER=mpicxx \
-D CMAKE_Fortran_COMPILER=mpif90 \
-D CMAKE_BUILD_TYPE=Release \
-D CMAKE_LIBRARY_PATH=$ACT_HOME/lib \
-D CMAKE_INCLUDE_PATH=$ACT_HOME/include \
-D Trilinos_ROOT=$ACT_HOME \
-D CMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
-D CMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
-D CMAKE_POSITION_INDEPENDENT_CODE=ON \
-D Xyce_PLUGIN_SUPPORT=ON \
$EDA_SRC/sandia-xyce-xyce  || exit 1


echo "==== build xyce ===="
make -j2 || exit 1
echo "==== build xyce c interface ===="
make xycecinterface -j || exit 1
echo "==== install xyce ===="
make install || exit 1

wget --quiet https://raw.githubusercontent.com/asyncvlsi/actsim/master/grab_xyce.sh || exit 1
bash grab_xyce.sh ./  || exit 1
mv xyce.in $ACT_HOME/include/
