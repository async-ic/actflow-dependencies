#!/bin/bash

if [ -d "../packaging" ]; then echo "please exec from repository root (one folder up)"; exit 1; fi

bash ./build_testing || exit 1

# final portable-rpath pass: give every ELF under ACT_HOME a clean relative rpath to
# ACT_HOME/lib. Replaces the per-package LDFLAGS/-Wl,-rpath hacks that mangle $ORIGIN semi sucsessful.
find "$ACT_HOME" -type f | while read -r f; do
    head -c4 "$f" 2>/dev/null | grep -q ELF || continue
    rel=$(realpath --relative-to="$(dirname "$f")" "$ACT_HOME/lib")
    patchelf --set-rpath "\$ORIGIN/${rel}" "$f" 2>/dev/null
done
