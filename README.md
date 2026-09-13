# actflow-dependencies
all dependencies required by actflow https://github.com/asyncvlsi/actflow

Built with MPI enabled from the **main** branch, in 5 portable variants.
The four linux ones only depend on libc and work with any linux/gnu OS with kernel
version newer than:

- **x86-64-v2** kernel version 3.10 or higher 
- **x86-64-v3** kernel version 5.14 or higher
- **x86-64-v4** kernel version 5.14 or higher
- **armv8.5-a** (aarch64) kernel version 5.14 or higher

the macOS one only depends on the base system (`/usr/lib`, `/System`):

- **applem1** (arm64, Apple silicon) macOS 12.0 Monterey or higher

[![pipeline status](https://lab.compute.dtu.dk/async-ic/eda/act-actflow-dependencies/badges/main/pipeline.svg)](https://lab.compute.dtu.dk/async-ic/eda/act-actflow-dependencies/-/pipelines)

[![Latest Release](https://lab.compute.dtu.dk/async-ic/eda/act-actflow-dependencies/-/badges/release.svg)](https://lab.compute.dtu.dk/async-ic/eda/act-actflow-dependencies/-/releases)

the builds are tested to work with prestine versions (no extra packages installed) of 
**x86-64-v2:**
the oldest release of each distro, proving the compatibility floor, plus the newer ones
that still get security updates
- centos:7.2+ # kernel 3.10, oldest RHEL
- RHEL 8 (or derivats RockyLinux, AlmaLinux, ...) # kernel 4.18
- opensuse leap 15 # 15.6, kernel 6.4
- Ubuntu LTS 16.04 # kernel 4.4, oldest ubuntu
- Ubuntu LTS 22.04 # kernel 5.15
- Debian 11 # bullseye, kernel 5.10, oldest debian
- Debian 12 # bookworm, kernel 6.1
- Fedora 25 # kernel 4.8

**x86-64-v3 and x86-64-v4:**
only releases still in their normal support cycle, once one drops to LTS/ESM or goes EOL
it is only covered by the v2 list above
- RHEL 9 (or derivats RockyLinux, AlmaLinux, ...) # kernel 5.14
- RHEL 10 (or derivats RockyLinux, AlmaLinux, ...) # kernel 6.12
- debian stable  # trixie, kernel 6.12
- debian testing # rolling
- ubuntu LTS 24.04 # kernel 6.8
- ubuntu LTS 26.04 # kernel 6.14
- opensuse leap 16 # 16.0, kernel 6.12
- archlinux latest # rolling
- fedora latest # rolling

**applem1:**
built with deployment target MacOS 12.0. Tested on:
- macOS 12 Monterey / 13 Ventura / 14 Sonoma
- macOS 15 Sequoia / 26 Tahoe / 27 Golden Gate

**armv8.5-a:**
tested on the mirrored arm64 tart VM images only, glibc 2.34 (rocky 9) is the floor
- RHEL 9 (or derivats RockyLinux, AlmaLinux, ...) # kernel 5.14
- debian 12 / 13 # bookworm, trixie
- ubuntu LTS 22.04 / 24.04
- fedora 38 / 39 / 42

# How to build it yourself

## requirements:
if you build on an older OS your package is compatible with more target platforms, thats why the v2 variant builds on centos7.2

the build brings its own gcc, cmake, bison and flex into `$ACT_HOME`, the host toolchain only has to
bootstrap those: gcc 11+, make, m4, autoconf, automake, bison, flex, gperf, libtool, python3, csh, patch,
texinfo, help2man, gettext, po4a, the gcc arithmetic libraries (gmp, mpfr, mpc), zlib and patchelf.

- rhel/centos/fedora: `dnf install gcc gcc-c++ gcc-gfortran m4 autoconf automake bison flex gperf libtool python3 tcsh patch texinfo help2man gettext-devel po4a which gmp-devel mpfr-devel libmpc-devel zlib-devel patchelf gzip`
  (the CI does this in `packaging/el9_install_build_system.sh`, centos7 needs the SCL toolchain, see `packaging/el7_install_build_system.sh`)
- debian/ubuntu: `apt install build-essential gfortran m4 autoconf automake bison flex gperf libtool python3 tcsh patch texinfo help2man gettext po4a libgmp-dev libmpfr-dev libmpc-dev zlib1g-dev patchelf gzip`
- macOS: Xcode plus the brew formulae in `packaging/macos_install_build_system.sh`; there clang is the
  host compiler (gcc has no aarch64-darwin target) and no fortran is built

## run the steps for building local

get the sources first - the source tarball of a release carries them in `src/`, a checkout needs
`git clone --recurse-submodules`. Then only `$ACT_HOME`, the install path, has to be set, everything
else is defaulted by `./build`:

```
export ACT_HOME=$(pwd)/opt/act
./build     # builds and installs the whole dependency tree into $ACT_HOME
./test      # linker/rpath tests against the install
```

this builds for the cpu of the machine you build on (`ARCH_LEVEL=native`) and produces no package.
Export `ARCH_LEVEL` yourself to get a portable build instead (see below); in CI an unset `ARCH_LEVEL`
fails the job rather than silently building something unportable.

`./clean` resets the source tree, needed before a re-run of `./build`.

## environment variables

`$ACT_HOME` is pointing to the install path, the only one without a default
`$EDA_SRC` is pointing to the folder containing the sources, defaults to `$(pwd)/src`
`$ARCH_LEVEL` selects the microarchitecture level to build for (`x86-64-v2`/`v3`/`v4`, `armv8.5-a`), injected into `CFLAGS`/`CXXFLAGS`/`FFLAGS`/`FCFLAGS`, defaults to `native`
`$MAKE_JOBS` is the `-j` level of every build script, defaults to the host cpu count (lower it if a compile gets OOM-killed, ~2GB per job)
`$PKG_ARCH` is the package/release name token, `$ARCH_LEVEL` on linux and `applem1` on macOS
(whose `ARCH_LEVEL` is `armv8.5-a` too and would collide), packaging only
`$SOEXT` is the shared object suffix the dependency build systems emit, `.so` or `.dylib`

for a packaged build the CI sets those from one place per platform: on centos7 `source packaging/el7_ci_build_environment.sh`,
on alma9/rocky9 `source packaging/el9_ci_build_environment.sh`, on macOS `source packaging/macos_ci_build_environment.sh`,
from the repository root to get them set up with act home in `/opt/act`.

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
  and their orphaned `tcl`, plus `readline`/`libffi`/`fmt`, were removed as unneeded; their submodules are
  commented out in `.gitmodules`)

# CI

Builds on GitLab CI (`.gitlab-ci.yml`): each variant builds and packages in its own job, then gets
tested against a matrix of clean-OS containers (rhel8, debian, ubuntu, opensuse, archlinux, fedora, ...) to
verify it only depends on libc. Releases (source + all packaged tarballs) are published as GitLab Releases
on `main`.

The macOS variant differs in where its checks run: the vanilla test images carry no developer
tools at all (`git`, `make`, `otool` and `clang` are xcode-select shims there), so the mach-o
link and relocation checks run in `build:applem1`, and the test matrix launches the shipped
binaries and asserts against what dyld actually loaded.
