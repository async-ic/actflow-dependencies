#!/bin/bash

# Build system for the ABI 5.14 variants (x86-64-v3/v4 on AlmaLinux 9, armv8.5-a on Rocky 9).

# tart VMs run the job as an unprivileged user with passwordless sudo, containers as root
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

$SUDO dnf install -y 'dnf-command(config-manager)' git wget
$SUDO dnf config-manager --set-enabled crb
$SUDO dnf install -y epel-release
echo "repo setup"
# gmp/mpfr/mpc/zlib devel: needed to configure/build the gcc bootstrap in 007-org-gnu-gcc.sh
$SUDO dnf install -y gcc gcc-c++ gcc-gfortran m4 autoconf automake bison flex gperf libtool python3 tcsh patch texinfo help2man gettext-devel po4a which gmp-devel mpfr-devel libmpc-devel zlib-devel chrpath gzip
echo "install done"
