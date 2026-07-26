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


# assert an ELF that loads $ACT_HOME libs has an $ORIGIN-relative RPATH/RUNPATH
# resolving to $ACT_HOME/lib (keeps the install relocatable); exits non-zero on
# a missing or absolute-only rpath. ELFs using only system libs are skipped.
check_rpath () {
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
  ldd_out=$(ldd $ACT_HOME/lib/$1)
  if [[ $ldd_out == *"not found"* || $ldd_out == *"missing"* || $ldd_out == *"No such file"* || $ldd_out == *"not a dynamic executable"* ]]; then
    echo "missing shared library: $ldd_out"
    exit 1
  fi
  #echo "Debug: $ldd_out"
  check_rpath "$ACT_HOME/lib/$1"
}

