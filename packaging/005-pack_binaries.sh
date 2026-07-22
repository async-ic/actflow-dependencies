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

if [ x$ACT_HOME = x ]
then
	echo "Please set the environment variable ACT_HOME to the install directory"
        exit 1
fi

echo 
echo "#### package the ACT_HOME install ####"
echo
if [ -d "../packaging" ]; then echo "please exec from repository root (one folder up)"; exit 1; fi

# move to the folder above act_home so the pathes inside the tar are nice
WORK_DIR=$(pwd)
mv actflow_dependency_build_* $ACT_HOME/
cd $ACT_HOME/..
tar -czf $WORK_DIR/actflow_dependencies_package_$(date '+%Y-%m-%d')_${ARCH_LEVEL:-unknown-arch}_${CI_COMMIT_SHORT_SHA:-local}.tar.gz $(realpath --relative-to ./ $ACT_HOME)
