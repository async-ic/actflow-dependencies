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

# DISABLED: abc build disabled, see build_scripts/disabled-026-yale-rmanohar-abc.sh

if [ -d "../tests" ]; then echo "please exec from repository root (one folder up)"; exit 1; fi
echo "#############################"
echo "# abc test for linking errors"

source tests/test_helper.sh

lookup_binary "abc"

