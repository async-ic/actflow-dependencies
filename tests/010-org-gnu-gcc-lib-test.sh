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

if [ -d "../tests" ]; then echo "please exec from repository root (one folder up)"; exit 1; fi
echo "#############################"
echo "# gcc lib test for linking errors"

source tests/test_helper.sh

# gcc builds libquadmath only where it provides __float128: i386/x86_64, ia64,
# loongarch, hppa and ppc64. aarch64 has none (long double is binary128 there),
# so the lib can never be packaged for it.
# macOS builds with the system clang and has no gcc at all (build_scripts/007): the
# OpenMP runtime is LLVM's libomp from 008, and there is no Fortran runtime because
# nothing Fortran is built.
if [ "$(uname -s)" = "Darwin" ]; then
	echo "skip gcc runtime libs: macOS builds with clang, see the libomp check below"
	lookup_shared_library "libomp${SOEXT}"
	exit 0
fi

case "$(uname -m)" in
i?86 | x86_64) lookup_shared_library "libquadmath${SOEXT}" ;;
*) echo "skip libquadmath${SOEXT}: not built by gcc on $(uname -m)" ;;
esac
lookup_shared_library "libgfortran${SOEXT}"
lookup_shared_library "libgomp${SOEXT}"
