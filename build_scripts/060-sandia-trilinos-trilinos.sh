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
echo "#### trilinos ####"
echo

cd $EDA_SRC/sandia-trilinos-trilinos
if [ ! -d build ]; then
	mkdir build
fi
# license
cp LICENSE $ACT_HOME/license/LICENSE_sandia-trilinos-trilinos
cat Copyright.txt >> $ACT_HOME/license/LICENSE_sandia-trilinos-trilinos
cd $EDA_SRC/sandia-trilinos-trilinos/build

cmake \
-G "Unix Makefiles" \
-D CMAKE_CXX_FLAGS="-O3 -fPIC ${CXXFLAGS}" \
-D CMAKE_C_FLAGS="-O3 -fPIC ${CFLAGS}" \
-D CMAKE_Fortran_FLAGS="-O3 -fPIC ${FFLAGS}" \
-D CMAKE_MAKE_PROGRAM="make" \
-D Trilinos_ENABLE_NOX=ON \
-D NOX_ENABLE_LOCA=ON \
-D Trilinos_ENABLE_EpetraExt=ON \
-D EpetraExt_BUILD_BTF=ON \
-D EpetraExt_BUILD_EXPERIMENTAL=ON \
-D EpetraExt_BUILD_GRAPH_REORDERINGS=ON \
-D Trilinos_ENABLE_TrilinosCouplings=ON \
-D Trilinos_ENABLE_Ifpack=ON \
-D Trilinos_ENABLE_Isorropia=ON \
-D Trilinos_ENABLE_AztecOO=ON \
-D Trilinos_ENABLE_Belos=ON \
-D Trilinos_ENABLE_Teuchos=ON \
-D Trilinos_ENABLE_COMPLEX=ON \
-D Trilinos_ENABLE_Amesos=ON \
-D Amesos_ENABLE_KLU=ON \
-D Trilinos_ENABLE_Amesos2=ON \
-D Amesos2_ENABLE_KLU2=ON \
-D Amesos2_ENABLE_Basker=ON \
-D Trilinos_ENABLE_Sacado=ON \
-D Trilinos_ENABLE_Stokhos=ON \
-D Trilinos_ENABLE_Kokkos=ON \
-D Trilinos_ENABLE_Zoltan=ON \
-D Trilinos_ENABLE_OpenMP=ON \
-D Trilinos_ENABLE_ShyLU=ON \
-D Trilinos_ENABLE_MueLu=ON \
-D Trilinos_ENABLE_ROL=ON \
-D Trilinos_ENABLE_ShyLU_DDCore=ON \
-D Trilinos_ENABLE_ShyLU_Node=ON \
-D Trilinos_ENABLE_ShyLU_NodeBasker=ON \
-D Trilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF \
-D CMAKE_CXX_STANDARD=17 \
-D CMAKE_POSITION_INDEPENDENT_CODE=ON \
-D TPL_ENABLE_AMD=ON \
-D AMD_LIBRARY_DIRS=$ACT_HOME/lib \
-D TPL_AMD_INCLUDE_DIRS=$ACT_HOME/include \
-D TPL_ENABLE_BLAS=ON \
-D TPL_ENABLE_LAPACK=ON \
-D TPL_ENABLE_MPI=ON \
-D CMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
-D CMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
-D CMAKE_INSTALL_PREFIX=$ACT_HOME \
-D CMAKE_LIBRARY_PATH=$ACT_HOME/lib \
-D CMAKE_INCLUDE_PATH=$ACT_HOME/include \
-D EIGEN3_ROOT=$ACT_HOME/include/eigen3 \
$EDA_SRC/sandia-trilinos-trilinos  || exit 1

cmake --build . -j2 -t install  || exit 1

