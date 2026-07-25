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

# DISABLED: unused, was src/yale-asyncvlsi-irsim
# https://github.com/asyncvlsi/irsim.git @ 3813495e55a21a024e62e21bd6993fac068a61b9

echo "############ Requires X11 and OpenGL #################"
if [ -z $BUILD_GUI ]; then
    exit 0;
fi

echo "#############################"
echo "# irsim"

cd $EDA_SRC/yale-asyncvlsi-irsim
# license
cp COPYRIGHT $ACT_HOME/license/LICENSE_yale-asyncvlsi-irsim

./configure --prefix=$ACT_HOME CFLAGS="-g -I${ACT_HOME}/include -L${ACT_HOME}/lib" LDFLAGS="-L${ACT_HOME}/lib -Wl,-rpath=\\$\$ORIGIN/../lib" || exit 1
make || exit 1
make install || exit 1

sed -i 's/\/root\/project\/act/\${ACT_HOME}/g' $ACT_HOME/bin/irsim

