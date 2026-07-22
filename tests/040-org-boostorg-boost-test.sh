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

lookup_shared_library "libboost_atomic.so"
lookup_shared_library "libboost_context.so"
lookup_shared_library "libboost_container.so"
lookup_shared_library "libboost_coroutine.so"
lookup_shared_library "libboost_date_time.so"
lookup_shared_library "libboost_contract.so"
lookup_shared_library "libboost_filesystem.so"
lookup_shared_library "libboost_fiber.so"
lookup_shared_library "libboost_regex.so"
lookup_shared_library "libboost_iostreams.so"
lookup_shared_library "libboost_graph.so"
lookup_shared_library "libboost_json.so"
lookup_shared_library "libboost_locale.so"
lookup_shared_library "libboost_nowide.so"
lookup_shared_library "libboost_log_setup.so"
lookup_shared_library "libboost_random.so"
lookup_shared_library "libboost_program_options.so"
lookup_shared_library "libboost_serialization.so"
lookup_shared_library "libboost_stacktrace_addr2line.so"
lookup_shared_library "libboost_stacktrace_noop.so"
lookup_shared_library "libboost_system.so"
lookup_shared_library "libboost_stacktrace_basic.so"
lookup_shared_library "libboost_wserialization.so"
lookup_shared_library "libboost_prg_exec_monitor.so"
lookup_shared_library "libboost_timer.so"
lookup_shared_library "libboost_type_erasure.so"
lookup_shared_library "libboost_unit_test_framework.so"
lookup_shared_library "libboost_wave.so"
lookup_shared_library "libboost_math_c99.so"
lookup_shared_library "libboost_math_c99f.so"
lookup_shared_library "libboost_math_c99l.so"
lookup_shared_library "libboost_math_tr1.so"
lookup_shared_library "libboost_math_tr1f.so"
lookup_shared_library "libboost_math_tr1l.so"
lookup_shared_library "libboost_chrono.so"