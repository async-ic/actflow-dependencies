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

# deps: trilinos submodule source | used by: 060-trilinos (gcc16 epetraext omp.h + zoltan metis proto)

# applies local source patches from extra/ needed to build the pinned submodule
# versions with the gcc16 toolchain. the sentinel skips re-applying on resume.

if [ ! -f patched_dependencies_v2 ]
then
   echo "Applying trilinos gcc16 source patches (epetraext omp.h; zoltan metis proto)"
   (cd src/sandia-trilinos-trilinos;
     patch -p0 < ../../extra/sandia-trilinos-trilinos-epetraext-amd-omp-gcc16.patch &&
     patch -p0 < ../../extra/sandia-trilinos-trilinos-zoltan-metis-parmetis-proto-gcc16.patch;
   ) || exit 1
   touch patched_dependencies_v2
fi
