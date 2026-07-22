#!/bin/bash
dnf install -y 'dnf-command(config-manager)' git wget
dnf config-manager --set-enabled crb
dnf install -y epel-release
echo "repo setup"
dnf install -y gcc gcc-c++ gcc-gfortran m4 autoconf automake bison flex libtool python3 tcsh patch texinfo gettext-devel po4a which
echo "install done"
