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

# deps: 007-gcc (fortran), 008-automake (autogen) | used by: 042-boost, 057-parmetis, 058-superlu_dist, 060-trilinos, 072-xyce

# => boost
# => trilinos (xyce => actsim)
# => galois (backend tools)

echo 
echo "#### MPICH ####"
echo

cd $EDA_SRC/org-pmodels-mpich
cp COPYRIGHT $ACT_HOME/license/LICENSE_org-pmodels-mpich

# accept host libtool 2.4.2 (mpich ships its own 2.4.4 files, not overwritten).
# automake >=1.15 comes from 008.
sed -i 's/ver=2.4.4/ver=2.4.2/' autogen.sh

./autogen.sh
./configure \
    --prefix=$ACT_HOME \
    --enable-fast=O3 \
    --enable-fortran=all \
    --enable-cxx \
    --enable-threads=runtime \
    CPPFLAGS="-I$ACT_HOME/include ${CPPFLAGS}" \
    LDFLAGS="-L$ACT_HOME/lib ${LDFLAGS} -Wl,-rpath=\\\$\$ORIGIN/../lib" \
    FFLAGS="-fallow-argument-mismatch ${FFLAGS}" \
    FCFLAGS="-fallow-argument-mismatch ${FCFLAGS}" || exit 1
make -j2 || exit 1
make install || exit 1

