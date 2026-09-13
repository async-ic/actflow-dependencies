#!/bin/bash

if [ -d "../packaging" ]; then echo "please exec from repository root (one folder up)"; exit 1; fi

# ./build runs the portable-install pass itself, so a local build is packageable as is
bash ./build || exit 1
