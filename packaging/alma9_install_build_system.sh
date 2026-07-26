#!/bin/bash
dnf install -y 'dnf-command(config-manager)' git wget
dnf config-manager --set-enabled crb
dnf install -y epel-release
echo "repo setup"
# gmp/mpfr/mpc/zlib devel: needed to configure/build the gcc bootstrap in 007-org-gnu-gcc.sh
dnf install -y gcc gcc-c++ gcc-gfortran m4 autoconf automake bison flex libtool python3 tcsh patch texinfo help2man gettext-devel po4a which gmp-devel mpfr-devel libmpc-devel zlib-devel chrpath
echo "install done"
