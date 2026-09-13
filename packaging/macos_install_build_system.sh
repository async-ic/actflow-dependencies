#!/bin/bash

# Build system for the applem1 variant (armv8.5-a on a macos-sequoia-xcode tart VM).

# Xcode supplies the host clang, ld, make, patch, gzip and install_name_tool; /bin/csh
# is part of the base system. Homebrew covers the autotools side and gcc's arithmetic
# libraries (gmp/mpfr/libmpc), the counterpart to the *-devel packages on el9.
# No patchelf/chrpath: install_name_tool does the rpath pass on mach-o.

set -eu

xcode-select -p >/dev/null || { echo "Xcode command line tools not available"; exit 1; }
echo "xcode $(xcodebuild -version 2>/dev/null | head -n1), sdk $(xcrun --show-sdk-version)"

brew install m4 autoconf automake bison flex gperf libtool python3 texinfo help2man gettext gmp mpfr libmpc isl
echo "install done"
