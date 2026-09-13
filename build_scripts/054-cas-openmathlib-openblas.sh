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

# deps: 007-gcc | used by: 060-trilinos (BLAS/LAPACK); provides libblas/liblapack symlinks

# macOS has no Fortran compiler available under the "ship only what we compiled" rule
# (gcc has no aarch64-darwin target), and OpenBLAS's LAPACK half is Fortran. The base
# system's Accelerate framework provides the same Fortran-ABI BLAS+LAPACK and ships with
# every macOS release.
#
# Accelerate cannot be handed to consumers as a library, though: cmake treats
# "-framework Accelerate" as a library list and renders it -lAccelerate, and tribits
# rejects the framework path outright ("not a valid lib file name") because it is neither
# lib<name>.<ext> nor a bare name. Frameworks also have no file on disk to link against,
# they live in the dyld shared cache.
#
# So build the libblas/liblapack this tree expects as shims that re-export the framework.
# Consumers then link -lblas/-llapack exactly as on linux and need no macOS-specific
# flags. Only the shim is shipped - Apple's code is not redistributed, the shim just
# records a load path into /System, which every macOS release provides.
if [ "$(uname -s)" = "Darwin" ]; then
	echo "#############################"
	echo "# BLAS/LAPACK (Accelerate re-export shims)"
	mkdir -p $ACT_HOME/lib
	SHIM_SRC=$EDA_SRC/accelerate_shim.c
	: > $SHIM_SRC
	for lib in blas lapack; do
		clang -dynamiclib -o $ACT_HOME/lib/lib${lib}${SOEXT} $SHIM_SRC \
			-Wl,-reexport_framework,Accelerate \
			-install_name @rpath/lib${lib}${SOEXT} || exit 1
	done
	rm -f $SHIM_SRC
	ls -l $ACT_HOME/lib/libblas${SOEXT} $ACT_HOME/lib/liblapack${SOEXT}
	exit 0
fi

echo "#############################"
echo "# BLAS"

cd $EDA_SRC/cas-openmathlib-openblas
# license
cp LICENSE $ACT_HOME/license/LICENSE_cas-openmathlib-openblas
#if [ ! -d build ]; then
#	mkdir build
#fi
#cd $EDA_SRC/cas-openmathlib-openblas/build
#cmake \
#-D CMAKE_INSTALL_PREFIX=$ACT_HOME \
#-D CMAKE_LIBRARY_PATH=$ACT_HOME/lib \
#-D CMAKE_INCLUDE_PATH=$ACT_HOME/include \
#-D CMAKE_EXE_LINKER_FLAGS=-Wl,-rpath,'$ORIGIN/../lib' \
#-D CMAKE_SHARED_LINKER_FLAGS=-Wl,-rpath,'$ORIGIN/../lib' \
#-D CMAKE_POSITION_INDEPENDENT_CODE=ON \
#-D CMAKE_BUILD_TYPE=Release \
#-D NUM_THREADS=64 \
#-D USE_OPENMP=1 \
#-D BUILD_STATIC_LIBS=ON \
#-D BUILD_SHARED_LIBS=ON \
#.. || exit 1
#sed -i 's/\/lib64/\/lib/g' cmake_install.cmake
#make -j || exit 1
#make install  || exit 1
# force TARGET: OpenBLAS's cpuid auto-detection misidentifies CPUs under some hypervisors/containers
case "$ARCH_LEVEL" in
	x86-64-v4) OPENBLAS_TARGET=SKYLAKEX ;;
	x86-64-v3) OPENBLAS_TARGET=HASWELL ;;
	x86-64-v2) OPENBLAS_TARGET=NEHALEM ;;
	armv9-a)   OPENBLAS_TARGET=ARMV9SME ;;
	# no per-8.x arm targets in OpenBLAS, generic ARMV8 base + DYNAMIC_ARCH runtime dispatch
	armv8.7-a | armv8.5-a | armv8-a) OPENBLAS_TARGET=ARMV8 ;;
	*) OPENBLAS_TARGET= ;;
esac

make -j$MAKE_JOBS TARGET=$OPENBLAS_TARGET DYNAMIC_ARCH=1 NUM_THREADS=32 USE_OPENMP=1 CPPFLAGS="-I$ACT_HOME/include ${CPPFLAGS}" LDFLAGS="-L$ACT_HOME/lib ${LDFLAGS}" || exit 1
make PREFIX=$ACT_HOME install  || exit 1
cd $ACT_HOME/lib/
ln -s libopenblas${SOEXT} libblas${SOEXT}
ln -s libopenblas${SOEXT} liblapack${SOEXT}

