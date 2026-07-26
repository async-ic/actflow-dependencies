# actflow-dependencies
all dependencies required by actflow https://github.com/asyncvlsi/actflow

Built with MPI enabled from the **main** branch, in 3 portable variants
that only depend on libc and work with any linux/gnu OS with kernel version newer than:

- **x86-64-v2** kernel version 3.10 or higher 
- **x86-64-v3** kernel version 5.14 or higher
- **x86-64-v4** kernel version 5.14 or higher

[![pipeline status](https://lab.compute.dtu.dk/async-ic/eda/act-actflow-dependencies/badges/main/pipeline.svg)](https://lab.compute.dtu.dk/async-ic/eda/act-actflow-dependencies/-/pipelines)

the builds are tested to work with prestine versions (no extra packages installed) of 
**x86-64-v2:**
- centos:7.2+ # kernel 3.10
- RHEL 8 (or derivats RockyLinux, AlmaLinux, ...) # kernel 4.18
- RHEL 9 (or derivats RockyLinux, AlmaLinux, ...) # kernel 5.14
- RHEL 10 (or derivats RockyLinux, AlmaLinux, ...) # kernel 6.12
- Debian oldoldstable # bullseye, kernel 5.10
- Ubuntu LTS 20.04  # kernel 5.4
- Ubuntu LTS 18.04  # kernel 4.15
- Ubuntu LTS 16.04  # kernel 4.4
- Fedora 20 # kernel 3.11

**x86-64-v3 and x86-64-v4:**
- RHEL 9 (or derivats RockyLinux, AlmaLinux, ...) # kernel 5.14
- RHEL 10 (or derivats RockyLinux, AlmaLinux, ...) # kernel 6.12
- debian stable    # trixie, kernel 6.12
- debian oldstable # bookworm, kernel 6.1
- ubuntu LTS 22.04 # kernel 5.15
- ubuntu LTS 24.04 # kernel 6.8
- ubuntu LTS 26.04 # kernel 6.14
- opensuse leap 15  # 15.6, kernel 6.4
- archlinux latest # rolling
- fedora latest # rolling

# How to Package and build

## requirements:
if you build on an older OS your package is compatible with more target platforms, thats why the v2 variant builds on centos7.2

you need gcc 11+, m4, make, autoconf, automake, bison, flex, libtool, python3, csh, patch, texinfo
(see `packaging/centos7_install_build_system.sh` for centos7/v2, `packaging/alma9_install_build_system.sh` for alma9/v3+v4)

## environment variables

`$ACT_HOME` is pointing to the install path
`$EDA_SRC` is pointing to the folder containing the sources
`$ARCH_LEVEL` selects the microarchitecture level to build for (`x86-64-v2`/`v3`/`v4`), injected into `CFLAGS`/`CXXFLAGS`/`FFLAGS`/`FCFLAGS`

on centos7 run `source packaging/centos7_ci_build_environment.sh`, on alma9 run `source packaging/alma9_ci_build_environment.sh`,
from the repository root to get them set up with act home in `/opt/act`.

## run the steps for building local

`./build` should do the trick after you have your buildsystem setup properly

`./test` runs the linker tests after the build+install

## run the steps for packaging

for running all the packaging steps in order simply execute on the root of the repo
`for script in packaging/0*.sh; do bash $script; done`
or run all the 00X-*****.sh script in assending order

### relation to the toplevel build/clear/test
the scripts in packaging actually run the top level sripts for you

## folder structure

- `src` contains all dependency sources
- `tests` contains all linkage test scripts and some application tests
- `packaging` contains the scripts for CI and packaging
- `build_scripts` contains all the build scripts for the dependencies (scripts prefixed `disabled-` are kept for
  reference but are not run - see the comment at the top of each for why, e.g. `abc`/`yosys`/`magic`/`irsim`/`tk`
  were removed as unneeded)

# CI

Builds on GitLab CI (`.gitlab-ci.yml`): each of the 3 variants builds and packages in its own job, then gets
tested against a matrix of clean-OS containers (rhel8, debian, ubuntu, opensuse, archlinux, fedora, ...) to
verify it only depends on libc. Releases (source + all 3 packaged tarballs) are published as GitLab Releases
on `main`.
