#!/bin/bash

if [ -d "../packaging" ]; then echo "please exec from repository root (one folder up)"; exit 1; fi

# ./build_testing runs the portable-install pass itself
bash ./build_testing || exit 1
