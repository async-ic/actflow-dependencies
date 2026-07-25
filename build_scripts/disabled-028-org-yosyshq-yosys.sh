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

# DISABLED: unused, was src/org-yosyshq-yosys
# https://github.com/yosyshq/yosys.git @ f109fa3d4c56fe33bc626c298e04d45ae510dd0e

echo "####################"
echo "# yosys"

cd $EDA_SRC/org-yosyshq-yosys

echo "CONFIG := gcc" > Makefile.conf
echo "PREFIX := $ACT_HOME" >> Makefile.conf
echo "LDLIBS += -lncurses" >> Makefile.conf
echo "ABCEXTERNAL := abc" >> Makefile.conf
echo "CXXFLAGS += -I${ACT_HOME}/include -L${ACT_HOME}/lib" >> Makefile.conf
echo "LDFLAGS += -L${ACT_HOME}/lib -Wl,-rpath=\\$\$ORIGIN/../lib" >> Makefile.conf
make -j2  || exit 1
make install || exit 1
cp COPYING $ACT_HOME/license/LICENSE_org-yosyshq-yosys

