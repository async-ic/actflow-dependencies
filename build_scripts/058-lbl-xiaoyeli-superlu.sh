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
# 


echo 
echo "#### superlu ####"
echo

cd $EDA_SRC/lbl-xiaoyeli-superlu
if [ ! -d build ]; then
	mkdir build
fi
cp License.txt $ACT_HOME/license/LICENSE_lbl-xiaoyeli-superlu


cd $EDA_SRC/lbl-xiaoyeli-superlu_dist
if [ ! -d build ]; then
	mkdir build
fi
# license

cp License.txt $ACT_HOME/license/LICENSE_lbl-xiaoyeli-superlu_dist
cd $EDA_SRC/lbl-xiaoyeli-superlu/build

cmake \
-D CMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
-D CMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
-D CMAKE_INSTALL_PREFIX=$ACT_HOME \
-D CMAKE_INSTALL_LIBDIR=lib \
-D CMAKE_LIBRARY_PATH=$ACT_HOME/lib \
-D CMAKE_INCLUDE_PATH=$ACT_HOME/include \
-D CMAKE_POSITION_INDEPENDENT_CODE=ON \
-D CMAKE_BUILD_TYPE=Release \
-D TPL_ENABLE_INTERNAL_BLASLIB=OFF \
$EDA_SRC/lbl-xiaoyeli-superlu || exit 1

make -j || exit 1
make install || exit 1

cd $EDA_SRC/lbl-xiaoyeli-superlu_dist/build
export PARMETIS_ROOT=$ACT_HOME
export PARMETIS_BUILD_DIR=$EDA_SRC/umn-karypislab-parmetis/build
cmake \
-D CMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
-D CMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
-D CMAKE_INSTALL_PREFIX=$ACT_HOME \
-D CMAKE_INSTALL_LIBDIR=lib \
-D CMAKE_LIBRARY_PATH=$ACT_HOME/lib \
-D CMAKE_INCLUDE_PATH=$ACT_HOME/include \
-D CMAKE_POSITION_INDEPENDENT_CODE=ON \
-D CMAKE_BUILD_TYPE=Release \
-D XSDK_INDEX_SIZE=64 \
-D TPL_ENABLE_INTERNAL_BLASLIB=OFF \
-D TPL_ENABLE_LAPACKLIB=ON \
-D XSDK_ENABLE_Fortran=ON \
-D CMAKE_C_COMPILER=mpicc \
-D CMAKE_CXX_COMPILER=mpic++ \
-D CMAKE_Fortran_COMPILER=mpif90 \
-D TPL_PARMETIS_LIBRARIES="${ACT_HOME}/lib/libparmetis.a;${ACT_HOME}/lib/libmetis.a;${ACT_HOME}/lib/libGKlib.a"  \
-D TPL_PARMETIS_INCLUDE_DIRS=${ACT_HOME}/include \
$EDA_SRC/lbl-xiaoyeli-superlu_dist  || exit 1

make -j || exit 1
make install || exit 1

