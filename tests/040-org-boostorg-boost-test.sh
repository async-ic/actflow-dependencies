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

if [ -d "../tests" ]; then echo "please exec from repository root (one folder up)"; exit 1; fi
echo "#############################"
echo "# libboost test for linking errors"

source tests/test_helper.sh

# what 042 requests through --with-libraries. interact links filesystem, log, log_setup
# and thread directly; Galois, Dali and phyDB require serialization and iostreams through
# find_package, which fails at configure time when either is absent even though neither is
# linked. b2 adds log_setup alongside log, and random, wserialization and a static-only
# exception as dependencies of the above. Everything else boost offers is header-only here.
lookup_shared_library "libboost_atomic${SOEXT}"
lookup_shared_library "libboost_chrono${SOEXT}"
lookup_shared_library "libboost_container${SOEXT}"
lookup_shared_library "libboost_date_time${SOEXT}"
lookup_shared_library "libboost_filesystem${SOEXT}"
lookup_shared_library "libboost_iostreams${SOEXT}"
lookup_shared_library "libboost_log${SOEXT}"
lookup_shared_library "libboost_log_setup${SOEXT}"
lookup_shared_library "libboost_serialization${SOEXT}"
lookup_shared_library "libboost_thread${SOEXT}"
