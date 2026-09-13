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

# deps: 007-gcc, 003-automake (autogen) | used by: downstream (FFI, runtime)

source packaging/relocate.sh

echo "#############################"
echo "# libffi"
cd $EDA_SRC/org-libffi-libffi
cp LICENSE $ACT_HOME/license/LICENSE_org-libffi-libffi
./autogen.sh || exit 1
./configure --prefix=$ACT_HOME CPPFLAGS="-I$ACT_HOME/include ${CPPFLAGS}" LDFLAGS="-L$ACT_HOME/lib ${LDFLAGS}" || exit 1
sed_i 's/\/..\/lib64//' Makefile
# libffi builds in a host-triple subdir: x86_64-*-linux-gnu / aarch64-*-linux-gnu on
# linux, aarch64-apple-darwin* on macOS (which has no lib64, so the fixup is a no-op)
for hostdir in *-linux-gnu* *-apple-darwin*; do
	[ -d "$hostdir" ] && sed_i 's/\/..\/lib64//' "$hostdir/Makefile"
done
make -j$MAKE_JOBS || exit 1
make install || exit 1
