#!/bin/bash
# DISABLED: no longer invoked, only consumers (magic, irsim, tk) are disabled, see build_scripts/disabled-08*.sh
# graphic libraries are not shipped in the package
export BUILD_GUI="true"
echo "yum install -y libX11-devel mesa-libGL-devel mesa-libGLU-devel | cat" | bash
