# actflow-dependencies
all dependencies required by actflow https://github.com/asyncvlsi/actflow

Built with MPI enabled from the **main** branch, tagged **rowling-mpi**, in 3 portable variants
that only depend on libc:

- **x86-64-v2** on CentOS 7 (the original/baseline toolchain)
- **x86-64-v3** on AlmaLinux 9
- **x86-64-v4** on AlmaLinux 9

[![pipeline status](https://lab.compute.dtu.dk/async-ic/eda/act-actflow-dependencies/badges/main/pipeline.svg)](https://lab.compute.dtu.dk/async-ic/eda/act-actflow-dependencies/-/pipelines)

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
