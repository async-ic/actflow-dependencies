#!/bin/bash

if [ -d "../packaging" ]; then echo "please exec from repository root (one folder up)"; exit 1; fi

source packaging/relocate.sh

bash ./build || exit 1

# final portable-install pass over ACT_HOME. Replaces the per-package LDFLAGS/-Wl,-rpath
# hacks that mangle $ORIGIN semi sucessfully.
relocate_tree "$ACT_HOME"
assert_portable_install "$ACT_HOME" || exit 1
