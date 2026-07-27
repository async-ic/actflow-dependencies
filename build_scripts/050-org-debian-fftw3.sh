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

# deps: 007-gcc | used by: 072-xyce (FFT), 060-trilinos

echo "#############################"
echo "# fftw"

cd $EDA_SRC/org-debian-fftw3
# license
cp COPYRIGHT $ACT_HOME/license/LICENSE_org-debian-fftw
cat COPYING >> $ACT_HOME/license/LICENSE_org-debian-fftw
#./bootstrap.sh 
./configure --prefix=$ACT_HOME \
 CFLAGS="-I${ACT_HOME}/include -L${ACT_HOME}/lib -fPIC ${CFLAGS}" \
 CPPFLAGS="-I${ACT_HOME}/include -L${ACT_HOME}/lib -fPIC" \
 LDFLAGS="-L${ACT_HOME}/lib -Wl,-rpath=\\$\$ORIGIN/../lib"  || exit 1
make -j  || exit 1
make install  || exit 1

