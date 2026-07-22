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

echo 
echo "#### build gcc libgfortran and dependencies ####"
echo

cd $EDA_SRC/org-gnu-gcc/
cp COPYING.LIB $ACT_HOME/license/LICENSE_org-gnu-gcc-lib
cat COPYING3.LIB >> $ACT_HOME/license/LICENSE_org-gnu-gcc-lib

# we are bypassing the normal gcc build and just build the libs

# for gfortran build in place
cp config-ml.in ../

cd $EDA_SRC/org-gnu-gcc/libgcc
cp gthr-posix.h gthr-default.h

echo 
echo "#### build libgfortran: libbacktrace ####"
echo

cd $EDA_SRC/org-gnu-gcc/libbacktrace
./configure --prefix=$ACT_HOME --with-pic --disable-multilib CPPFLAGS="-I$ACT_HOME/include ${CPPFLAGS}" LDFLAGS="-L$ACT_HOME/lib ${LDFLAGS} -Wl,-rpath=\\\$\$ORIGIN/../lib,-rpath=$ACT_HOME/lib" || exit 1
make || exit 1
make install || exit 1

echo 
echo "#### build libgfortran: libquadmath ####"
echo

cd $EDA_SRC/org-gnu-gcc/libquadmath
if [ ! -d build ]; then
	mkdir build
fi
cd $EDA_SRC/org-gnu-gcc/libquadmath/build
../configure --prefix=$ACT_HOME --with-pic --disable-multilib CPPFLAGS="-I$ACT_HOME/include ${CPPFLAGS}" LDFLAGS="-L$ACT_HOME/lib ${LDFLAGS} -Wl,-rpath=\\\$\$ORIGIN/../lib,-rpath=$ACT_HOME/lib" || exit 1
sed -i 's/\/..\/lib64//' Makefile
make  || exit 1
make install || exit 1

echo 
echo "#### build gcc libgfortran ####"
echo

cd $EDA_SRC/org-gnu-gcc/libgfortran
./configure --prefix=$ACT_HOME --with-pic --disable-multilib CPPFLAGS="-I$ACT_HOME/include ${CPPFLAGS}" LDFLAGS="-L$ACT_HOME/lib ${LDFLAGS} -Wl,-rpath=\\\$\$ORIGIN/../lib,-rpath=$ACT_HOME/lib" || exit 1
sed -i 's/\/..\/lib64//' Makefile
make  || exit 1
make install || exit 1

echo 
echo "#### build gcc libgomp ####"
echo
cd $EDA_SRC/org-gnu-gcc/libgomp
if [ ! -d build ]; then
	mkdir build
fi
cd $EDA_SRC/org-gnu-gcc/libgomp/build
../configure --prefix=$ACT_HOME --with-pic --disable-multilib CPPFLAGS="-I$ACT_HOME/include ${CPPFLAGS}" LDFLAGS="-L$ACT_HOME/lib ${LDFLAGS} -Wl,-rpath=\\\$\$ORIGIN/../lib,-rpath=$ACT_HOME/lib" || exit 1
make  || exit 1
make install || exit 1