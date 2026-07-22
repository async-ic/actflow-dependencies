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
# ARCH_LEVEL is the literal compiler -march value, checked per platform:
#   x86-64-v2            Linux/x86_64 - /proc/cpuinfo flags (works on any glibc/kernel)
#   x86-64-v3/v4          Linux/x86_64 - ld.so hwcaps tag (glibc >= 2.33, flag set is large/version-sensitive)
#   armv8.5-a/8.7-a       Linux/aarch64 - ld.so hwcaps tags, macOS/arm64 - hw.optional.arm.FEAT_* sysctls.
#                          Every mandatory feature of that baseline *that has a userspace-visible flag*
#                          is checked; some (CSV2/CSV3/HCX/XS, ...) are EL-only/informational and can't
#                          be probed from userspace, so they're left out.

set -u

if [ -z "${ARCH_LEVEL:-}" ]; then
	echo "Please set the environment variable ARCH_LEVEL (x86-64-v2|x86-64-v3|x86-64-v4|armv8.5-a|armv8.7-a)"
	exit 1
fi

OS=$(uname -s)
MACHINE=$(uname -m)

# dump CPU model + raw capability data on failure, so a bad runner is diagnosable from the CI log alone
print_cpu_info() {
	echo "--- cpu info ($OS/$MACHINE) ---"
	case "$OS" in
	Linux)
		grep -m1 '^model name\|^Features' /proc/cpuinfo
		grep -m1 '^flags\|^Features' /proc/cpuinfo
		local ldso
		ldso=$(command -v /lib64/ld-linux-x86-64.so.2 || command -v /lib/ld-linux-x86-64.so.2 || command -v /lib/ld-linux-aarch64.so.1)
		[ -n "$ldso" ] && "$ldso" --help 2>&1 | grep -i supported
		;;
	Darwin)
		sysctl -n machdep.cpu.brand_string 2>/dev/null
		sysctl -a 2>/dev/null | grep '^hw.optional'
		;;
	esac
	echo "----------------"
}

fail() {
	echo "$1"
	print_cpu_info
	exit 1
}

require_platform() {
	case "$OS/$MACHINE" in
	"$1") ;;
	*) fail "ARCH_LEVEL=${ARCH_LEVEL} requires $1, running on $OS/$MACHINE" ;;
	esac
}

find_ldso() {
	case "$MACHINE" in
	x86_64) command -v /lib64/ld-linux-x86-64.so.2 || command -v /lib/ld-linux-x86-64.so.2 ;;
	aarch64) command -v /lib/ld-linux-aarch64.so.1 || command -v /lib64/ld-linux-aarch64.so.1 ;;
	esac
}

# on Linux glibc's dynamic linker knows its own supported glibc-hwcaps tags - x86-64-v2/v3/v4
# tiers on x86_64, individual feature names (e.g. "ssbs") on aarch64 - so delegate to it instead
# of hand-enumerating flags. Checks that every given tag is supported (AND); no args = nothing to check.
check_linux_hwcaps() {
	[ $# -eq 0 ] && return 0
	local ldso help missing=""
	ldso=$(find_ldso)
	[ -z "$ldso" ] && fail "cannot locate the dynamic linker, unable to verify ${ARCH_LEVEL} support"
	help=$("$ldso" --help 2>&1)
	for tag in "$@"; do
		echo "$help" | grep -q "${tag} (supported" || missing="$missing $tag"
	done
	[ -n "$missing" ] && fail "runner does not support ${ARCH_LEVEL} (missing hwcaps:$missing)"
}

# macOS exposes individual Arm feature bits as hw.optional.arm.FEAT_* sysctls (value "1" = present).
# Checks that every given FEAT_* name is present (AND); no args = nothing to check.
check_macos_hwcaps() {
	[ $# -eq 0 ] && return 0
	local missing=""
	for feat in "$@"; do
		[ "$(sysctl -n "hw.optional.arm.${feat}" 2>/dev/null)" = "1" ] || missing="$missing $feat"
	done
	[ -n "$missing" ] && fail "host CPU does not support ${ARCH_LEVEL} (missing:$missing)"
}

case "$ARCH_LEVEL" in
x86-64-v2)
	require_platform "Linux/x86_64"
	flags=$(grep -m1 '^flags' /proc/cpuinfo)
	missing=""
	for f in cx16 lahf_lm popcnt sse4_1 sse4_2 ssse3; do
		echo "$flags" | grep -qw "$f" || missing="$missing $f"
	done
	[ -n "$missing" ] && fail "host CPU does not support x86-64-v2, missing flags:$missing"
	;;
x86-64-v3 | x86-64-v4)
	require_platform "Linux/x86_64"
	check_linux_hwcaps "$ARCH_LEVEL"
	;;
armv8.5-a)
	case "$OS/$MACHINE" in
	Linux/aarch64) check_linux_hwcaps dit flagm flagm2 frint sb ssbs ;;
	Darwin/arm64) check_macos_hwcaps FEAT_DIT FEAT_FlagM FEAT_FlagM2 FEAT_FRINTTS FEAT_SB FEAT_SSBS ;;
	*) fail "ARCH_LEVEL=armv8.5-a requires Linux/aarch64 or macOS/arm64, running on $OS/$MACHINE" ;;
	esac
	;;
armv8.7-a)
	case "$OS/$MACHINE" in
	Linux/aarch64) check_linux_hwcaps dit flagm flagm2 frint sb ssbs bf16 i8mm ecv wfxt afp ;;
	Darwin/arm64) check_macos_hwcaps FEAT_DIT FEAT_FlagM FEAT_FlagM2 FEAT_FRINTTS FEAT_SB FEAT_SSBS FEAT_BF16 FEAT_I8MM FEAT_ECV FEAT_WFXT FEAT_AFP ;;
	*) fail "ARCH_LEVEL=armv8.7-a requires Linux/aarch64 or macOS/arm64, running on $OS/$MACHINE" ;;
	esac
	;;
*)
	fail "unknown ARCH_LEVEL '${ARCH_LEVEL}' (expected x86-64-v2|x86-64-v3|x86-64-v4|armv8.5-a|armv8.7-a)"
	;;
esac

echo "confirmed ${ARCH_LEVEL} support on $OS/$MACHINE"
