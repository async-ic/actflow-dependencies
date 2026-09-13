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

# deps: host clang, 005-cmake, org-llvm-llvm-project submodule (current release) | used by: 057-parmetis, 060-trilinos, 072-xyce, actflow
#       Galois/Dali/TritonRoute-WXL/act/interact/fpga_proto

# macOS only. The linux variants get their OpenMP runtime as libgomp from the gcc built
# in 007; macOS has no gcc and the system clang ships no OpenMP runtime at all, so build
# LLVM's libomp into ACT_HOME. It is the only compiler runtime the macOS package ships -
# libc++ and the Accelerate framework come from the base system and are never
# redistributed.
#
# The runtime has to track the compiler, not fluid's pin. clang emits
# __kmpc_dispatch_deinit for dynamic-schedule loops (Kokkos::Schedule<Kokkos::Dynamic>,
# reached through trilinos/amesos2), and that entry point only exists in the runtime from
# LLVM 19 on. The 14.0.6 runtime builds fine and passes a simple parallel-for, then fails
# to link xyce - hence the explicit symbol check at the end of this script.
#
# So llvm is carried as two submodules: org-llvm-llvm-project on the current release
# branch for this runtime, and org-llvm-llvm-project-14 pinned at llvmorg-14.0.6, which
# 105 needs because fluid does not build against anything newer. Both are fetched shallow,
# so only the checked-out commit is available - the sources have to come from the
# submodule itself, not from another tag in the same clone.

if [ "$(uname -s)" != "Darwin" ]; then
	echo "skip libomp: linux uses libgomp from the gcc built in 007"
	exit 0
fi

LLVM_SRC=$EDA_SRC/org-llvm-llvm-project

echo "#############################"
echo "# libomp (LLVM OpenMP runtime, llvm $(sed -n 's/.*set(LLVM_VERSION_MAJOR \([0-9]*\)).*/\1/p' $LLVM_SRC/cmake/Modules/LLVMVersion.cmake 2>/dev/null | head -1))"

cp $LLVM_SRC/llvm/LICENSE.TXT $ACT_HOME/license/LICENSE_org-llvm-openmp || exit 1

mkdir -p $LLVM_SRC/build-openmp
cd $LLVM_SRC/build-openmp || exit 1
# configure through runtimes/, not openmp/: llvm removed the legacy standalone openmp
# build ("The legacy standalone build mode has been removed"). Only the openmp runtime is
# enabled, nothing else of llvm is built.
cmake \
-D CMAKE_INSTALL_PREFIX=$ACT_HOME \
-D CMAKE_BUILD_TYPE=Release \
-D CMAKE_POSITION_INDEPENDENT_CODE=ON \
-D LLVM_ENABLE_RUNTIMES=openmp \
-D LIBOMP_ENABLE_SHARED=ON \
-G "Unix Makefiles" \
$LLVM_SRC/runtimes || exit 1
make -j$MAKE_JOBS || exit 1
make install || exit 1

# the dispatch entry point trilinos/kokkos needs; a runtime too old links everything else
# and only fails at the xyce link an hour later, so check it here instead
nm -gU $ACT_HOME/lib/libomp${SOEXT} | grep -q "__kmpc_dispatch_deinit" || {
	echo "the libomp built from org-llvm-llvm-project does not export __kmpc_dispatch_deinit" >&2
	echo "(needs llvm 19 or newer; check what that submodule is pinned to)" >&2
	exit 1
}
