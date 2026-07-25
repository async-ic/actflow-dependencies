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

# DISABLED: unused, was src/yale-rmanohar-abc
# https://github.com/rmanohar/abc.git @ 54758a10095bce564f499ea975bee6abba647674

echo "#############################"
echo "# ABC"

cd $EDA_SRC/yale-rmanohar-abc
cp copyright.txt $ACT_HOME/license/LICENSE_berkeley-abc
mv $EDA_SRC/yale-rmanohar-abc/Makefile $EDA_SRC/yale-rmanohar-abc/Makefile.original

echo "LIBS += -lncurses" > $EDA_SRC/yale-rmanohar-abc/Makefile
echo "CFLAGS += -I${ACT_HOME}/include -L${ACT_HOME}/lib" >> $EDA_SRC/yale-rmanohar-abc/Makefile
echo "LDFLAGS += -L${ACT_HOME}/lib -Wl,-rpath=\\$\$ORIGIN/../lib" >> $EDA_SRC/yale-rmanohar-abc/Makefile
cat $EDA_SRC/yale-rmanohar-abc/Makefile.original >> $EDA_SRC/yale-rmanohar-abc/Makefile
make ABC_USE_LIBSTDCXX=1 -j || exit 1
# so build broken but probably not used
#make -j ABC_USE_PIC=1 libabc.so
make -j ABC_USE_LIBSTDCXX=1  libabc.a || exit 1
mv abc $ACT_HOME/bin/
mv libabc.* $ACT_HOME/lib/
