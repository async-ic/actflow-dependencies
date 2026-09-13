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


# shared object suffix; the test jobs run without the build environment sourced
if [ -z "${SOEXT:-}" ]; then
  case "$(uname -s)" in
  Darwin) SOEXT=.dylib ;;
  *) SOEXT=.so ;;
  esac
fi

# mach-o inspection needs the xcode tools; the vanilla macOS images carry none, so there
# only the dyld run check applies and each skip is logged.

# lexical path normalisation, the part of "realpath -m" macOS does not provide
norm_path () {
  local p=$1 out="" seg IFS=/
  for seg in $p; do
    case "$seg" in
    '' | .) ;;
    ..) out=${out%/*} ;;
    *) out="$out/$seg" ;;
    esac
  done
  printf '%s' "${out:-/}"
}

# canonicalise the data volume firmlink to the spelling dyld prints; /System/Volumes/Data/x
# and /x are one file, and no resolver collapses them
strip_data_volume () {
  case "$1" in
  /System/Volumes/Data/*) printf '%s' "${1#/System/Volumes/Data}" ;;
  /System/Volumes/Data) printf '/' ;;
  *) printf '%s' "$1" ;;
  esac
}

# physical path via cd + pwd -P, macOS having no "realpath -m"; falls back to the deepest
# existing directory, then to the lexical form. Image comparisons resolve both sides this way
# to match dyld; the path is taken as given, as norm_path breaks a relative $ACT_HOME.
real_path () {
  local p=$1 d b r
  [ -n "$p" ] || { norm_path "$p"; return; }
  if r=$(cd "$p" 2>/dev/null && pwd -P); then strip_data_volume "$r"; return; fi
  d=$(dirname "$p"); b=$(basename "$p")
  if r=$(cd "$d" 2>/dev/null && pwd -P); then
    r=$(strip_data_volume "$r")
    case "$r" in
    /) printf '%s' "/$b" ;;
    *) printf '%s' "$r/$b" ;;
    esac
    return
  fi
  norm_path "$p"
}

# in-place sed; BSD sed requires an explicit backup suffix, GNU sed rejects one
sed_i () {
  if sed --version >/dev/null 2>&1; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

# walk the component suites as upstream's `make runtest` does (act/scripts/Makefile.std):
#   if [ -d test -a -x test/run.sh ]; then (cd test; ./run.sh); fi
# recursed over the subdirectories. Nothing here compiles, so the shell does it instead: the
# vanilla macOS images have no usable make. Suites nested deeper (act/test/dl, chp2prs/test/*)
# are driven by their parent run.sh, as under make.
run_test_suites () {
  local root=$1 d rc=0
  for d in $(find "$root" -type d -name test | sort); do
    [ -x "$d/run.sh" ] || continue
    echo "#### ${d#"$root"/} ####"
    ( cd "$d" && ./run.sh ) || rc=1
  done
  return $rc
}

# assert a mach-o that leaves the base OS loads through @rpath and carries a
# @loader_path rpath resolving to $ACT_HOME/lib (keeps the install relocatable).
check_rpath_macho () {
  local file=$1
  local act=$(real_path "$ACT_HOME")
  # otool must run, not merely exist: without the xcode tools /usr/bin/otool is a shim that
  # fails, which would leave this check silently passing on empty output
  if ! otool --version >/dev/null 2>&1; then
    echo "skip rpath check: otool not available (no xcode tools on this host)"
    return 0
  fi
  local dir=$(dirname "$(real_path "$file")")
  local dep abs= entry exp
  # every non-system load must go through @rpath, an absolute one cannot survive a move
  for dep in $(otool -L "$file" 2>/dev/null | tail -n +2 | awk '{print $1}'); do
    case "$dep" in
    @rpath/*)
      [ -e "$ACT_HOME/lib/${dep#@rpath/}" ] && continue
      echo "missing shared library: $file needs $dep, not in $ACT_HOME/lib"
      exit 1
      ;;
    @* | /usr/lib/* | /System/*) continue ;;
    esac
    echo "wrong install name: $file loads '$dep' by absolute path"
    exit 1
  done
  # base-OS-only binaries need no rpath
  otool -L "$file" 2>/dev/null | tail -n +2 | grep -q '@rpath/' || return 0
  for entry in $(otool -l "$file" 2>/dev/null | awk '/LC_RPATH/{r=1} r&&/ path /{print $2; r=0}'); do
    exp=${entry//@loader_path/$dir}
    [ "$(real_path "$exp")" = "$act/lib" ] || continue
    if [ "$exp" != "$entry" ]; then   # changed -> @loader_path was present, relocatable
      echo "rpath ok: $file -> $entry"
      return 0
    fi
    abs=$entry                        # resolves but hardcoded absolute
  done
  if [ -n "$abs" ]; then
    echo "wrong rpath: $file uses absolute '$abs', use @loader_path-relative to $act/lib"
    exit 1
  fi
  echo "missing rpath: $file loads @rpath libs but has no LC_RPATH reaching $act/lib"
  exit 1
}

# launch the binary and assert it got past image loading, and that every image it pulled in
# is the install or the base OS. Needs no tooling; still alive when the timer fires is the
# pass condition.
lookup_binary_macho () {
  local file=$1
  local act=$(real_path "$ACT_HOME")
  local tmp=$(mktemp) out bad pid watcher
  DYLD_PRINT_LIBRARIES=1 "$file" </dev/null >/dev/null 2>"$tmp" &
  pid=$!
  (sleep 5; kill -9 "$pid" 2>/dev/null) >/dev/null 2>&1 &
  watcher=$!
  wait "$pid" 2>/dev/null
  # grouped: the shell announces the killed timer job on its own stderr, not the job's
  { kill "$watcher"; wait "$watcher"; } 2>/dev/null
  out=$(cat "$tmp"); rm -f "$tmp"

  case "$out" in
  *"Library not loaded"* | *"image not found"* | *"Symbol not found"*)
    echo "missing shared library: $(printf '%s' "$out" | grep -m2 -e 'Library not loaded' -e 'Symbol not found' -e 'Reason')"
    exit 1
    ;;
  esac
  # only this pid: DYLD_PRINT_LIBRARIES is inherited and children share the stderr
  bad=$(printf '%s\n' "$out" | sed -n "s/^dyld\[$pid\]: <[^>]*> //p")
  if [ -z "$bad" ]; then
    # stripped by the hardened runtime, or no image was loaded; the launch still passed
    echo "skip image check: $file reported no loaded images"
    return 0
  fi
  local img keep=""
  while IFS= read -r img; do
    case "$img" in
    "$act"/* | /usr/lib/* | /System/* | /bin/* | /sbin/* | /usr/bin/* | /usr/sbin/* | /usr/libexec/*) continue ;;
    esac
    keep=$keep$img$'\n'
  done <<<"$bad"
  bad=${keep%$'\n'}
  if [ -n "$bad" ]; then
    echo "non-portable dependency: $file loads images outside the install and the base OS:"
    printf '%s\n' "$bad" | sed 's/^/  /'
    exit 1
  fi
  echo "loads ok: $file"
}

# assert an ELF that loads $ACT_HOME libs carries an $ORIGIN-relative RPATH/RUNPATH resolving
# to $ACT_HOME/lib (keeps the install relocatable); ELFs using only system libs are skipped.
check_rpath () {
  if [ "$(uname -s)" = "Darwin" ]; then
    check_rpath_macho "$1"
    return
  fi
  if ! command -v readelf >/dev/null; then
    echo "skip rpath check: readelf not found"
    return 0
  fi
  local file=$1
  local act=$(realpath -m "$ACT_HOME")
  # system-only deps (libc, ...) need no rpath
  if ! ldd "$file" 2>/dev/null | grep -qF "=> $act/"; then
    return 0
  fi
  local dir=$(dirname "$(realpath -m "$file")")
  local paths=$(readelf -d "$file" 2>/dev/null | sed -n 's/.*(R\(UN\)\?PATH).*\[\(.*\)\]/\2/p')
  if [ -z "$paths" ]; then
    echo "missing rpath: $file loads $act libs but has no RPATH/RUNPATH"
    exit 1
  fi
  # split entries on ':'/newline; $ORIGIN expands to the file's own dir
  local entry exp abs= IFS=$':\n'
  for entry in $paths; do
    exp=${entry//\$\{ORIGIN\}/$dir}; exp=${exp//\$ORIGIN/$dir}
    [ "$(realpath -m "$exp")" = "$act/lib" ] || continue
    if [ "$exp" != "$entry" ]; then   # changed -> $ORIGIN was present, relocatable
      echo "rpath ok: $file -> $entry"
      return 0
    fi
    abs=$entry                        # resolves but hardcoded absolute
  done
  if [ -n "$abs" ]; then
    echo "wrong rpath: $file uses absolute '$abs', use \$ORIGIN-relative to $act/lib"
    exit 1
  fi
  echo "wrong rpath: $file has [$paths], none resolves to $act/lib"
  exit 1
}

lookup_binary () {
  if [ x$(command -v $1) = x ]; then
    echo "missing $1"
    exit 1
  fi
  echo "found $1"
  if [ "$(uname -s)" = "Darwin" ]; then
    lookup_binary_macho "$(command -v $1)"
    check_rpath "$(command -v $1)"
    return
  fi
  #echo "ldd $(command -v $1)"
  ldd_out=$(ldd $(command -v $1))
  if [[ $ldd_out == *"not found"* || $ldd_out == *"missing"* || $ldd_out == *"No such file"* || $ldd_out == *"not a dynamic executable"* ]]; then
    echo "missing shared library: $ldd_out"
    exit 1
  fi
  #echo "Debug: $ldd_out"
  check_rpath "$(command -v $1)"
}

lookup_shared_library () {
  if [ ! -f $ACT_HOME/lib/$1 ]; then
    echo "missing $1"
    exit 1
  fi
  echo "found $1"
  if [ "$(uname -s)" = "Darwin" ]; then
    check_rpath "$ACT_HOME/lib/$1"
    return
  fi
  ldd_out=$(ldd $ACT_HOME/lib/$1)
  if [[ $ldd_out == *"not found"* || $ldd_out == *"missing"* || $ldd_out == *"No such file"* || $ldd_out == *"not a dynamic executable"* ]]; then
    echo "missing shared library: $ldd_out"
    exit 1
  fi
  #echo "Debug: $ldd_out"
  check_rpath "$ACT_HOME/lib/$1"
}

