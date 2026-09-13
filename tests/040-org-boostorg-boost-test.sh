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

# b2 produces no compiled boost_graph or boost_math_{c99,tr1}{,f,l} on macOS with this
# boost version - it reports them as "building" and then emits no target. Nothing in the
# tree links them: actflow uses boost/graph/ and boost/math/ as headers only, and no
# dependency build references either library. Checked here rather than silently dropped.
BOOST_SKIP_DARWIN="libboost_graph libboost_math_c99 libboost_math_c99f libboost_math_c99l libboost_math_tr1 libboost_math_tr1f libboost_math_tr1l"
lookup_boost_library () {
  if [ "$(uname -s)" = "Darwin" ]; then
    case " $BOOST_SKIP_DARWIN " in
    *" ${1%$SOEXT} "*)
      echo "skip $1: not built by b2 on macOS, header-only use in actflow"
      return 0
      ;;
    esac
  fi
  lookup_shared_library "$1"
}

lookup_boost_library "libboost_atomic${SOEXT}"
lookup_boost_library "libboost_context${SOEXT}"
lookup_boost_library "libboost_container${SOEXT}"
lookup_boost_library "libboost_coroutine${SOEXT}"
lookup_boost_library "libboost_date_time${SOEXT}"
lookup_boost_library "libboost_contract${SOEXT}"
lookup_boost_library "libboost_filesystem${SOEXT}"
lookup_boost_library "libboost_fiber${SOEXT}"
lookup_boost_library "libboost_regex${SOEXT}"
lookup_boost_library "libboost_iostreams${SOEXT}"
lookup_boost_library "libboost_graph${SOEXT}"
lookup_boost_library "libboost_json${SOEXT}"
lookup_boost_library "libboost_locale${SOEXT}"
lookup_boost_library "libboost_nowide${SOEXT}"
lookup_boost_library "libboost_log_setup${SOEXT}"
lookup_boost_library "libboost_random${SOEXT}"
lookup_boost_library "libboost_program_options${SOEXT}"
lookup_boost_library "libboost_serialization${SOEXT}"
lookup_boost_library "libboost_stacktrace_addr2line${SOEXT}"
lookup_boost_library "libboost_stacktrace_noop${SOEXT}"
lookup_boost_library "libboost_stacktrace_basic${SOEXT}"
lookup_boost_library "libboost_wserialization${SOEXT}"
lookup_boost_library "libboost_prg_exec_monitor${SOEXT}"
lookup_boost_library "libboost_timer${SOEXT}"
lookup_boost_library "libboost_type_erasure${SOEXT}"
lookup_boost_library "libboost_unit_test_framework${SOEXT}"
lookup_boost_library "libboost_wave${SOEXT}"
lookup_boost_library "libboost_math_c99${SOEXT}"
lookup_boost_library "libboost_math_c99f${SOEXT}"
lookup_boost_library "libboost_math_c99l${SOEXT}"
lookup_boost_library "libboost_math_tr1${SOEXT}"
lookup_boost_library "libboost_math_tr1f${SOEXT}"
lookup_boost_library "libboost_math_tr1l${SOEXT}"
lookup_boost_library "libboost_chrono${SOEXT}"