#!/bin/bash

#
# Copyright 2026 Ole Richter - Technical University of Denmark, University of Groningen

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

# fail fast if the runner can't confirm ARCH_LEVEL support, instead of failing deep into build/test with a SIGILL.
# v2 is checked against /proc/cpuinfo flags (works on any glibc/kernel).
# v3/v4 need glibc >= 2.33 hwcaps detection (ld.so --help), since the required flag set is large/version-sensitive.

if [ x$ARCH_LEVEL = x ]; then
	echo "Please set the environment variable ARCH_LEVEL (x86-64-v2|x86-64-v3|x86-64-v4)"
	exit 1
fi

if [ "$ARCH_LEVEL" = "x86-64-v2" ]; then
	flags=$(grep -m1 '^flags' /proc/cpuinfo)
	missing=""
	for f in cx16 lahf_lm popcnt sse4_1 sse4_2 ssse3; do
		echo "$flags" | grep -qw "$f" || missing="$missing $f"
	done
	if [ -n "$missing" ]; then
		echo "host CPU does not support x86-64-v2, missing flags:$missing"
		exit 1
	fi
	echo "confirmed x86-64-v2 support"
	exit 0
fi

LDSO=$(command -v /lib64/ld-linux-x86-64.so.2 || command -v /lib/ld-linux-x86-64.so.2)
if [ -z "$LDSO" ]; then
	echo "cannot locate ld-linux-x86-64.so.2, unable to verify ${ARCH_LEVEL} support"
	exit 1
fi

if ! "$LDSO" --help 2>&1 | grep -q "${ARCH_LEVEL} (supported"; then
	echo "runner does not support ${ARCH_LEVEL}"
	exit 1
fi

echo "confirmed ${ARCH_LEVEL} support"
