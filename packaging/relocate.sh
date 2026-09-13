#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ole Richter - Technical University of Denmark
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

# Sourced, not executed. Holds the portable-install pass and the host helpers
# macOS does not provide.
#
# relocate_tree <root>: give every binary under <root> a relative rpath to
# <root>/lib, so the install runs from any path.
#   linux  ELF     RPATH $ORIGIN/<rel>                                 patchelf
#   macos  Mach-O  id and LC_LOAD_DYLIB -> @rpath/<name>,
#                  LC_RPATH -> @loader_path/<rel>                      install_name_tool
#
# install_name_tool re-signs ad-hoc, so the rewritten binaries stay loadable.
# A real signing identity applied later replaces that signature.

# relative path from directory $1 to path $2, both absolute; neither has to exist.
rel_path() {
	local from=${1%/} to=${2%/} up=""
	from=${from:-/}
	to=${to:-/}
	[ "$from" = "$to" ] && { printf '.'; return; }
	# walk $from up until it contains (or is) $to; the "/" in the patterns keeps
	# a sibling with a shared prefix (act / actfoo) from matching
	while :; do
		case "$to" in
		"$from" | "$from"/*) break ;;
		esac
		[ "$from" = "/" ] && break
		from=$(dirname "$from")
		up="${up}../"
	done
	local rest=${to#"$from"}
	rest=${rest#/}
	[ -n "$rest" ] && printf '%s' "${up}${rest}" || printf '%s' "${up%/}"
}

# cpu count; nproc is GNU-only
cpu_count() {
	if command -v nproc >/dev/null 2>&1; then
		nproc
	else
		sysctl -n hw.ncpu
	fi
}

# total physical memory in MB; _PHYS_PAGES is glibc-only
mem_total_mb() {
	if getconf _PHYS_PAGES >/dev/null 2>&1; then
		echo $(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / 1024 / 1024))
	else
		echo $(($(sysctl -n hw.memsize) / 1024 / 1024))
	fi
}

# in-place sed; BSD sed requires an explicit backup suffix, GNU sed rejects one
sed_i() {
	if sed --version >/dev/null 2>&1; then
		sed -i "$@"
	else
		sed -i '' "$@"
	fi
}

is_elf() {
	head -c4 "$1" 2>/dev/null | grep -q ELF
}

# only loadable images carry install names and rpaths. Static archives are link-time
# input (and file(1) calls a fat one a "Mach-O universal binary", while otool -L prints
# its member headers, which read like dependency paths); object files carry neither.
is_macho() {
	case "$(file -b "$1" 2>/dev/null)" in
	*"current ar archive"*) return 1 ;;
	*Mach-O*executable* | *Mach-O*"shared library"* | *Mach-O*bundle*) return 0 ;;
	esac
	return 1
}

# Mach-O: point the binary's own id, its $root loads and its rpath at @rpath/@loader_path.
# $1 file, $2 root, $3 relative path from the file's directory to $root/lib
_relocate_macho() {
	local f=$1 root=$2 rel=$3 id dep

	# own id: consumers recorded whatever this was at link time, and their
	# LC_LOAD_DYLIB is rewritten to the same @rpath/<basename> below
	id=$(otool -D "$f" 2>/dev/null | sed -n '2p')
	case "$id" in
	"" | @*) ;;
	*) install_name_tool -id "@rpath/$(basename "$id")" "$f" 2>/dev/null || true ;;
	esac

	# loads resolved out of $root/lib: matched by basename, so a path recorded
	# from a build tree rather than from $root is caught too. System libs and
	# names $root/lib does not carry are left alone.
	otool -L "$f" 2>/dev/null | tail -n +2 | awk '{print $1}' | while read -r dep; do
		case "$dep" in
		"" | @* | /usr/lib/* | /System/*) continue ;;
		esac
		[ -e "$root/lib/$(basename "$dep")" ] || continue
		install_name_tool -change "$dep" "@rpath/$(basename "$dep")" "$f" 2>/dev/null || true
	done

	# absolute rpaths cannot survive a move; @loader_path/@executable_path ones are kept
	otool -l "$f" 2>/dev/null | awk '/LC_RPATH/{r=1} r&&/ path /{print $2; r=0}' | while read -r p; do
		case "$p" in
		/*) install_name_tool -delete_rpath "$p" "$f" 2>/dev/null || true ;;
		esac
	done
	install_name_tool -add_rpath "@loader_path/${rel}" "$f" 2>/dev/null || true
}

# macOS: after relocate_tree the install must be both self-contained and relocatable.
# Two things are refused:
#   - a load outside the install and the base OS: a dependency we neither compiled nor
#     may redistribute, e.g. a cmake project quietly finding a brew library
#   - a load still naming $root by absolute path: relocation did not take, and the
#     install breaks as soon as it moves. install_name_tool cannot rewrite every mach-o
#     (tcl appends its zipfs archive past __LINKEDIT and the tool refuses the file), and
#     relocate_tree tolerates that failure, so catch it here rather than in the tests.
assert_portable_install() {
	local root=${1:-$ACT_HOME} f dep bad=0
	[ "$(uname -s)" = "Darwin" ] || return 0
	while IFS= read -r -d '' f; do
		is_macho "$f" || continue
		for dep in $(otool -L "$f" 2>/dev/null | tail -n +2 | awk '{print $1}'); do
			case "$dep" in
			"$root"/*)
				echo "not relocated: ${f#$root/} -> $dep" >&2
				bad=1
				;;
			@* | /usr/lib/* | /System/*) ;;
			*)
				echo "foreign dependency: ${f#$root/} -> $dep" >&2
				bad=1
				;;
			esac
		done
	done < <(find "$root" -type f -print0)
	[ $bad -eq 0 ] || {
		echo "refusing to package: the install is not self-contained or not relocatable" >&2
		return 1
	}
}

# $1 install root (defaults to $ACT_HOME)
relocate_tree() {
	local root=${1:-$ACT_HOME} f rel
	[ -n "$root" ] || {
		echo "relocate_tree: no root given and ACT_HOME unset" >&2
		return 1
	}

	case "$(uname -s)" in
	Darwin)
		find "$root" -type f -print0 | while IFS= read -r -d '' f; do
			is_macho "$f" || continue
			_relocate_macho "$f" "$root" "$(rel_path "$(dirname "$f")" "$root/lib")"
		done
		;;
	*)
		find "$root" -type f -print0 | while IFS= read -r -d '' f; do
			is_elf "$f" || continue
			rel=$(rel_path "$(dirname "$f")" "$root/lib")
			# some failures are expected (static binaries, ...), the tests cover the result
			patchelf --set-rpath "\$ORIGIN/${rel}" "$f" 2>/dev/null || true
		done
		;;
	esac
}
