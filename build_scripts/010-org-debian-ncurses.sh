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

# deps: 007-gcc | used by: 012-libedit, 020-readline

echo "#############################"
echo "# ncurses"
cd $EDA_SRC/org-debian-ncurses
# Shared configure args for both passes.
# --disable-widec: ncurses 6.6 defaults to ABI 6, which enables widec and names the
# libs libncursesw/libtinfow; classic consumers (libedit, readline) look for -lncurses/
# -ltinfo and fail. non-wide restores those names (the pre-6.6 ABI-5 default behaviour).
# --enable-root-environ: honour $TERMINFO as root (nothing setuid here) - a secondary
# path for terminals outside the compiled-in fallback set below. it needs
# cf_cv_multiuser=yes: the probe reads /etc/passwd, and in a CI image without a regular
# user it silently drops the whole root/setuid option block, restricting root instead.
# --with-terminfo-dirs: the compiled-in DB dir is the build $prefix and dies on
# relocation; the host DB covers the terminals outside the fallback set (xterm*).
common_cfg=(
  --disable-widec
  --enable-root-environ
  cf_cv_multiuser=yes
  --with-terminfo-dirs=/etc/terminfo:/lib/terminfo:/usr/share/terminfo:/usr/lib/terminfo:/usr/local/share/terminfo
  --with-cxx-binding
  --with-cxx-shared
  --with-xterm-kbs=del
  --without-ada
  --without-manpages
  --with-shared
  --with-termlib
  --with-versioned-syms
  --without-debug
  --prefix "$ACT_HOME"
  CPPFLAGS="-I$ACT_HOME/include ${CPPFLAGS}"
  LDFLAGS="-L$ACT_HOME/lib ${LDFLAGS} -Wl,-rpath=\\\$\$ORIGIN/../lib"
)

# Two-pass build for compiled-in terminfo fallbacks:
# the compiled DB dir is baked to the build $prefix (dead after relocation), so without
# them libedit/readline-linked tools warn "Cannot read termcap database" on any host
# lacking a DB. --with-fallbacks compiles the common terminals into libtinfo so they
# resolve with no DB and no env - robust against relocation and root.
# Its generator (MKfallback.sh) needs a version-matched tic/infocmp to compile 6.6's
# terminfo.src (host tic 5.9 is too old); pass 1 installs them, pass 2 uses them.
./configure "${common_cfg[@]}" || exit 1
make -j || exit 1
make install || exit 1

# pass 2: regenerate with fallbacks using the just-installed 6.6 tic/infocmp. MKfallback
# reads the freshly compiled entries via `infocmp -A <tmpdir>` (explicit path), so the
# root/$TERMINFO restriction does not apply during generation. xterm/xterm-256color are
# omitted: their use=-resolved entries exceed terminfo's 4096-byte limit so tic can't
# stage them (they aren't in the on-disk DB either); dumb (the CI's $TERM) + the vt/
# screen/ansi set below are what headless tools need and all fit.
make distclean || exit 1
./configure "${common_cfg[@]}" \
  --with-fallbacks=dumb,linux,vt100,ansi,screen,screen-256color \
  --with-tic-path="$ACT_HOME/bin/tic" \
  --with-infocmp-path="$ACT_HOME/bin/infocmp" \
  || exit 1
make -j || exit 1
make install || exit 1
cp COPYING $ACT_HOME/license/LICENSE_ncurses.txt

