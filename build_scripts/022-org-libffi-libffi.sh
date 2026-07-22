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

echo "#############################"
echo "# libffi"
# frozen for centos7 (ABI_LEVEL 3.10): newer libffi drops support for it
case "$ABI_LEVEL" in
	3.10) LIBFFI_SRC=org-libffi-libffi-abi_3.10 ;;
	*)    LIBFFI_SRC=org-libffi-libffi ;;
esac

cd $EDA_SRC/$LIBFFI_SRC
cp LICENSE $ACT_HOME/license/LICENSE_org-libffi-libffi
./autogen.sh || exit 1
./configure --prefix=$ACT_HOME CPPFLAGS="-I$ACT_HOME/include ${CPPFLAGS}" LDFLAGS="-L$ACT_HOME/lib ${LDFLAGS} -Wl,-rpath=\\\$\$ORIGIN/../lib,-rpath=$ACT_HOME/lib" || exit 1
sed -i 's/\/..\/lib64//' Makefile
cd x86*
sed -i 's/\/..\/lib64//' Makefile
cd $EDA_SRC/$LIBFFI_SRC
make -j || exit 1
make install || exit 1
