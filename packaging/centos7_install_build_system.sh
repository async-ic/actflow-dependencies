#!/bin/bash

# repoints EOL centos7 repos from dead mirrorlist to vault.centos.org; re-run after centos-release-scl (it re-adds its own repo files)
fix_centos_repos_for_vault() {
  sed -i -e 's/^mirrorlist=/#mirrorlist=/g' \
         -e 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' \
         /etc/yum.repos.d/CentOS-*.repo
}

fix_centos_repos_for_vault
# upgraded: base image's CA bundle predates GitHub's TLS cert, breaks https downloads otherwise
yum install -y centos-release-scl git wget yum-utils ca-certificates
fix_centos_repos_for_vault

yum-config-manager --enable rhel-server-rhscl-7-rpms
# disabled: unused, and its "# baseurl=" (space) doesn't match fix_centos_repos_for_vault's pattern
yum-config-manager --disable centos-sclo-sclo

echo "repo setup"
# gmp/mpfr/mpc/zlib devel: needed to configure/build the gcc bootstrap in 007-org-gnu-gcc.sh
echo "yum install -y devtoolset-11 m4 autoconf automake bison flex gperf libtool python3 csh patch texinfo help2man gettext-devel po4a gmp-devel mpfr-devel libmpc-devel zlib-devel chrpath gzip | cat" | bash
echo "install done"
