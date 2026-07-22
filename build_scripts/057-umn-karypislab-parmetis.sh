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
echo "#### GKlib ####"
echo 

cd $EDA_SRC/umn-karypislab-gklib
if [ ! -d build ]; then
	mkdir build
fi
cp LICENSE $ACT_HOME/license/LICENSE_umn-karypislab-gklib

cd $EDA_SRC/umn-karypislab-gklib/build

cmake \
-D CMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
-D CMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
-D CMAKE_INSTALL_PREFIX=$ACT_HOME \
-D CMAKE_LIBRARY_PATH=$ACT_HOME/lib \
-D CMAKE_INCLUDE_PATH=$ACT_HOME/include \
-D CMAKE_POSITION_INDEPENDENT_CODE=ON \
-D CMAKE_BUILD_TYPE=Release \
-D OPENMP=set \
-D CMAKE_C_FLAGS="-D_POSIX_C_SOURCE=199309L ${CFLAGS}" \
$EDA_SRC/umn-karypislab-gklib || exit 1

make -j || exit 1
make install || exit 1

echo 
echo "#### metis ####"
echo 

cd $EDA_SRC/umn-karypislab-metis
if [ ! -d build ]; then
	mkdir build
fi
cp LICENSE $ACT_HOME/license/LICENSE_umn-karypislab-metis

BUILDDIR=$EDA_SRC/umn-karypislab-metis/build \
make config i64=set r64=set CONFIG_FLAGS="-D CMAKE_EXE_LINKER_FLAGS=-Wl,-rpath,'$ORIGIN/../lib' -D CMAKE_SHARED_LINKER_FLAGS=-Wl,-rpath,'$ORIGIN/../lib' -D CMAKE_INSTALL_PREFIX=$ACT_HOME -D CMAKE_LIBRARY_PATH=$ACT_HOME/lib -D CMAKE_INCLUDE_PATH=$ACT_HOME/include -D CMAKE_POSITION_INDEPENDENT_CODE=ON -D CMAKE_BUILD_TYPE=Release -D OPENMP=set "\
 || exit 1
cd $EDA_SRC/umn-karypislab-metis/build
make -j || exit 1
make install || exit 1

echo 
echo "#### parmetis ####"
echo 

cd $EDA_SRC/umn-karypislab-parmetis
if [ ! -d build ]; then
	mkdir build
fi
cp LICENSE $ACT_HOME/license/LICENSE_umn-karypislab-parmetis

cd $EDA_SRC/umn-karypislab-parmetis/build

cmake \
-D CMAKE_C_COMPILER=mpicc \
-D CMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
-D CMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
-D CMAKE_INSTALL_PREFIX=$ACT_HOME \
-D CMAKE_LIBRARY_PATH=$ACT_HOME/lib \
-D CMAKE_INCLUDE_PATH=$ACT_HOME/include \
-D CMAKE_POSITION_INDEPENDENT_CODE=ON \
-D CMAKE_BUILD_TYPE=Release \
-D OPENMP=set \
-D CMAKE_C_FLAGS="-D_POSIX_C_SOURCE=199309L ${CFLAGS}" \
$EDA_SRC/umn-karypislab-parmetis || exit 1

make -j || exit 1
make install || exit 1
