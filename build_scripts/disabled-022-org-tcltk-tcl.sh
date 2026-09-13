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

# DISABLED: orphaned, its only consumers (magic, irsim, tk) are also disabled; nothing
# but tclsh itself linked libtcl.

# deps: 010-zlib | used by: downstream magic/irsim (runtime)

# tcl appends its script library (zipfs) to libtcl*.dylib. That leaves data past the
# __LINKEDIT segment, and install_name_tool then refuses the file outright:
#   "the __LINKEDIT segment does not cover the end of the file (can't be processed)"
# So the final portable-install pass cannot repair this library and both halves have to
# be right at link time:
#   - its own id comes from DYLIB_INSTALL_DIR, pointed at @rpath here
#   - the names it records for its dependencies come from THEIR install names, so give
#     what is already installed its @rpath ids first
TCL_DYLIB_DIR=""
TCL_LDFLAGS_EXTRA=""
if [ "$(uname -s)" = "Darwin" ]; then
	source packaging/relocate.sh
	relocate_tree "$ACT_HOME"
	TCL_DYLIB_DIR="DYLIB_INSTALL_DIR=@rpath"
	# the same applies to its LC_RPATH: install_name_tool cannot add one afterwards, and
	# without it the @rpath names above only resolve through whatever loaded the library.
	# lib/ is the library's own directory, so @loader_path is the relative path to it.
	TCL_LDFLAGS_EXTRA=" -Wl,-rpath,@loader_path"
fi

echo "#############################"
echo "# tcl"
cd $EDA_SRC/org-tcltk-tcl
cp license.terms $ACT_HOME/license/LICENSE_org-tcltk-tcl
cd unix
./configure --prefix=$ACT_HOME  CPPFLAGS="-I$ACT_HOME/include ${CPPFLAGS}" LDFLAGS="-L$ACT_HOME/lib ${LDFLAGS}${TCL_LDFLAGS_EXTRA}" || exit 1
make -j$MAKE_JOBS $TCL_DYLIB_DIR || exit 1
make install $TCL_DYLIB_DIR || exit 1
if [ ! -f $ACT_HOME/bin/tclsh ]; then
  cd $ACT_HOME/bin/
  ln -s tclsh* tclsh
fi
