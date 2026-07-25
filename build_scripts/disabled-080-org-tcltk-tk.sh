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

# DISABLED: orphaned, only consumers (magic, irsim) are also disabled.

echo "############ Requires X11 and OpenGL #################"
if [ -z $BUILD_GUI ]; then
    exit 0;
fi

echo "#############################"
echo "# tk"

if [ ! -f $EDA_SRC/org-tcltk-tcl/unix/tclConfig.sh ]; then
  cd $EDA_SRC/org-tcltk-tcl/unix
  ./configure --prefix=$ACT_HOME
fi

cd $EDA_SRC/org-tcltk-tk
cp license.terms $ACT_HOME/license/LICENSE_org-tcltk-tk
cd unix
./configure --prefix=$ACT_HOME --with-tcl=$EDA_SRC/org-tcltk-tcl/unix CFLAGS="-I${ACT_HOME}/include -L${ACT_HOME}/lib" LDFLAGS="-L${ACT_HOME}/lib -Wl,-rpath=\\$\$ORIGIN/../lib"  || exit 1
make -j || exit 1
make install || exit 1
