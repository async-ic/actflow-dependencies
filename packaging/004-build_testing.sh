#!/bin/bash

if [ -d "../packaging" ]; then echo "please exec from repository root (one folder up)"; exit 1; fi

source packaging/relocate.sh

bash ./build_testing || exit 1

# final portable-install pass over ACT_HOME, covering the newly added binaries.
relocate_tree "$ACT_HOME"
assert_portable_install "$ACT_HOME" || exit 1
