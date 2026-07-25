#!/bin/bash

#
# Copyright 2026 Ole Richter - Technical University of Denmark, University of Groningen

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

# builds a fully self-hosted gcc 16 (c,c++,fortran) into $ACT_HOME. $ACT_HOME/bin
# is first on PATH, so every later build_scripts/*.sh compiles with gcc 16 instead
# of the host/devtoolset compiler; the shipped package carries a complete, matching
# compiler + runtime (libstdc++/libgcc_s/libgfortran/libgomp/libquadmath).

echo
echo "#### build a fully bootstrapped gcc 16, installed into ACT_HOME ####"
echo

cd $EDA_SRC/org-gnu-gcc/
cp COPYING.LIB $ACT_HOME/license/LICENSE_org-gnu-gcc-lib
cat COPYING3.LIB >> $ACT_HOME/license/LICENSE_org-gnu-gcc-lib

# stage 1: throwaway gcc 16 (c,c++) built by the host compiler, single-pass -
# only exists to host stage 2, GCC's own sources only need a C++11 host.
echo
echo "#### stage 1: throwaway gcc 16 (c,c++), built by the host compiler ####"
echo

BOOTSTRAP_ROOT=$EDA_SRC/../gcc-bootstrap
rm -rf $BOOTSTRAP_ROOT
mkdir -p $BOOTSTRAP_ROOT/stage1-build

cd $BOOTSTRAP_ROOT/stage1-build
$EDA_SRC/org-gnu-gcc/configure --prefix=$BOOTSTRAP_ROOT/stage1 \
	--enable-languages=c,c++ --disable-multilib --disable-bootstrap --with-pic || exit 1
make -j$(nproc) || exit 1
make install || exit 1

# stage 2: gcc 16 (c,c++,fortran), 3-stage self-comparing bootstrap, installed
# into $ACT_HOME. Sanitizers/libitm/nls are dropped (unused here); install-strip
# drops debug symbols - both cut install size (cc1plus: ~410MB -> ~46MB).
echo
echo "#### stage 2: gcc 16 (c,c++,fortran), properly bootstrapped, installed into ACT_HOME ####"
echo

mkdir -p $BOOTSTRAP_ROOT/stage2-build
cd $BOOTSTRAP_ROOT/stage2-build
# PATH/CC/CXX must be exported, not just prefixed on configure: configure
# records them as bare words, so make re-resolves "gcc"/"g++" via PATH later -
# a prefix on the configure line alone would fall back to the host compiler.
export PATH=$BOOTSTRAP_ROOT/stage1/bin:$PATH
export CC=gcc CXX=g++
# CFLAGS/LDFLAGS on configure cover gcc's own host tools; target runtime libs
# (libstdc++/libgfortran/...) are governed by *_FOR_TARGET instead.
# rpath is a '$'-free placeholder, not the real value: gcc's recursive make
# forwarding mangles a literal '$ORIGIN' (both here and in BOOT_LDFLAGS below).
# chrpath overwrites it with the real rpath post-install, see below.
$EDA_SRC/org-gnu-gcc/configure --prefix=$ACT_HOME --libdir=$ACT_HOME/lib \
	--enable-languages=c,c++,fortran --disable-multilib --disable-libsanitizer --disable-libitm --disable-nls --with-pic \
	CFLAGS_FOR_TARGET="-I$ACT_HOME/include ${CFLAGS}" \
	CXXFLAGS_FOR_TARGET="-I$ACT_HOME/include ${CXXFLAGS}" \
	LDFLAGS_FOR_TARGET="-L$ACT_HOME/lib ${LDFLAGS} -Wl,-rpath=RPATH_PLACEHOLDER_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" || exit 1
# BOOT_LDFLAGS must be a `make` argument: gcc's configure doesn't substitute
# it, only make's STAGE1_LDFLAGS/POSTSTAGE1_LDFLAGS combination picks it up.
BOOT_LDFLAGS="-Wl,-rpath=RPATH_PLACEHOLDER_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
make BOOT_LDFLAGS="$BOOT_LDFLAGS" -j$(nproc) || exit 1
make BOOT_LDFLAGS="$BOOT_LDFLAGS" install-strip || exit 1

rm -rf $BOOTSTRAP_ROOT

# x86_64-linux hardcodes runtime libs into lib64/ regardless of --libdir (that
# only covers gcc's own host-side bits) - consolidate into lib/ to match the
# rest of the project's convention (rpath, -L flags, ...).
if [ -d $ACT_HOME/lib64 ]; then
	mv $ACT_HOME/lib64/* $ACT_HOME/lib/
	rmdir $ACT_HOME/lib64
fi

# patch the real rpath over the placeholder on every ELF file that got one;
# relative depth to lib/ varies by location, so it's computed per file.
find $ACT_HOME -type f -print0 | while IFS= read -r -d '' f; do
	chrpath "$f" >/dev/null 2>&1 || continue
	chrpath -r "\$ORIGIN/$(realpath --relative-to="$(dirname "$f")" "$ACT_HOME/lib")" "$f" || exit 1
done || exit 1

# libbacktrace isn't installed by gcc's own "make install" (an internal helper
# lib, not a public target library) - build it standalone, using the gcc we
# just installed.
echo
echo "#### build libbacktrace ####"
echo

cd $EDA_SRC/org-gnu-gcc/libbacktrace
./configure --prefix=$ACT_HOME --with-pic --disable-multilib CPPFLAGS="-I$ACT_HOME/include ${CPPFLAGS}" LDFLAGS="-L$ACT_HOME/lib ${LDFLAGS} -Wl,-rpath=\\\$\$ORIGIN/../lib" || exit 1
make || exit 1
make install || exit 1
