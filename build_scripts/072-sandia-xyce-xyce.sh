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

source packaging/relocate.sh

echo "#############################"
echo "# xyce"

# macOS: no Fortran compiler. BLAS/LAPACK come from the libblas/liblapack
# Accelerate shims 054 builds. Trilinos installs static libraries,
# so they do not record the OpenMP runtime they were built against - xyce must link it.
XYCE_FORTRAN="-D CMAKE_Fortran_COMPILER=mpif90"
XYCE_LINK_EXTRA=""
XYCE_CXX_COMPAT=""
if [ "$(uname -s)" = "Darwin" ]; then
	XYCE_FORTRAN=""
	XYCE_LINK_EXTRA=" -lomp"
	# trilinos' Sacado headers (Kokkos_LayoutContiguous/LayoutNatural.hpp) specialize
	# std::is_same, which is formally undefined; clang promoted that to an error. Demote
	# it for xyce, which pulls those headers in - trilinos itself never compiles them.
	XYCE_CXX_COMPAT="-D CMAKE_CXX_FLAGS=-Wno-error=invalid-specialization"
fi

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
${XYCE_FORTRAN} \
${XYCE_CXX_COMPAT} \
-D CMAKE_BUILD_TYPE=Release \
-D CMAKE_LIBRARY_PATH=$ACT_HOME/lib \
-D CMAKE_INCLUDE_PATH=$ACT_HOME/include \
-D Trilinos_ROOT=$ACT_HOME \
-D CMAKE_EXE_LINKER_FLAGS="-L${ACT_HOME}/lib${XYCE_LINK_EXTRA}" \
-D CMAKE_SHARED_LINKER_FLAGS="-L${ACT_HOME}/lib${XYCE_LINK_EXTRA}" \
-D CMAKE_POSITION_INDEPENDENT_CODE=ON \
-D Xyce_PLUGIN_SUPPORT=ON \
$EDA_SRC/sandia-xyce-xyce  || exit 1


echo "==== build xyce ===="
make -j2 || exit 1
echo "==== build xyce c interface ===="
make xycecinterface -j$MAKE_JOBS || exit 1
echo "==== install xyce ===="
make install || exit 1

wget --quiet https://raw.githubusercontent.com/asyncvlsi/actsim/master/grab_xyce.sh || exit 1
bash grab_xyce.sh ./  || exit 1
# relocate xyce.in: grab_xyce.sh copies Xyce's build link.txt verbatim, baking absolute
# build paths. actsim `include`s xyce.in in its Makefile ($(ACT_HOME) defined), so rewrite
# the install prefix to $(ACT_HOME), the xyce build-src rpath to the installed lib dir, and
# the bare libxyce shared object to -lxyce (resolved via actsim's -L$(ACT_HOME)/lib).
sed_i -e "s|${ACT_HOME}|\$(ACT_HOME)|g" \
       -e "s|${EDA_SRC}/sandia-xyce-xyce/build/src|\$(ACT_HOME)/lib|g" \
       -e "s| libxyce${SOEXT} | -lxyce |g" \
       xyce.in
mv xyce.in $ACT_HOME/include/
