echo "environment variables "

if [ -d "../build_scripts" ]; then echo "please exec from repository root (one folder up)"; exit 1; fi


if [ -z $EDA_SRC ]; then
    export EDA_SRC=$(pwd)/src
fi
echo "EDA_SRC $EDA_SRC"

if [ -z $ACT_HOME ]; then
    export ACT_HOME=/opt/act
fi
echo "ACT_HOME $ACT_HOME"

# M1 and later; 000-check_arch_level.sh verifies it against the hw.optional.arm.FEAT_* sysctls
if [ -z $ARCH_LEVEL ]; then
    export ARCH_LEVEL=armv8.5-a
fi
echo "ARCH_LEVEL $ARCH_LEVEL"

# macOS floor, the counterpart to the kernel/glibc ABI_LEVEL of the linux variants.
# 12.0 is the oldest release the test matrix carries an image for.
if [ -z $ABI_LEVEL ]; then
    export ABI_LEVEL=12.0
fi
export MACOSX_DEPLOYMENT_TARGET=$ABI_LEVEL
echo "ABI_LEVEL $ABI_LEVEL (MACOSX_DEPLOYMENT_TARGET)"

# package/release name token: ARCH_LEVEL alone would collide with the linux aarch64 build
if [ -z $PKG_ARCH ]; then
    export PKG_ARCH=applem1
fi
echo "PKG_ARCH $PKG_ARCH"

# shared library suffix the dependency build systems emit natively
export SOEXT=.dylib

# brew installs GNU libtool g-prefixed; autoreconf picks it up from here. Putting its
# gnubin on PATH instead would shadow /usr/bin/libtool, which is Apple's archive tool.
export LIBTOOLIZE=glibtoolize

# the automake built into ACT_HOME searches its own share/aclocal plus the dirlist that
# automake ships, which names /usr/share/aclocal - a path macOS does not have. libtool's
# LT_INIT and friends live under brew's prefix instead, so autoreconf fails with
# "Libtool library used but 'LIBTOOL' is undefined" unless aclocal is pointed at them.
export ACLOCAL_PATH="$(brew --prefix)/share/aclocal${ACLOCAL_PATH:+:${ACLOCAL_PATH}}"

# Dali's cmake/FindOpenMPPackage.cmake reads this to locate libomp, defaulting to
# "brew --prefix libomp" when unset. Point it at our own libomp (008) instead - the
# brew one must never end up in the package. Everything else resolves OpenMP through
# find_package(OpenMP), which picks up ACT_HOME via CMAKE_LIBRARY_PATH/CMAKE_INCLUDE_PATH.
export HOMEBREW_LIBOMP_PREFIX=$ACT_HOME

# macOS builds with the system clang: gcc has no aarch64-darwin target (see 007). Only
# the compiler runtime we build ourselves is shipped - libomp from 008; libc++ and the
# Accelerate framework (BLAS/LAPACK, replacing openblas) come from the base system and
# are never redistributed. No Fortran compiler exists under that rule, so FFLAGS/FCFLAGS
# are not set and mpich/trilinos/xyce build with Fortran off.
export CC=clang
export CXX=clang++
export SDKROOT=$(xcrun --show-sdk-path)
echo "SDKROOT $SDKROOT"

# ACT_HOME/bin holds the cmake/bison/flex this build produces and must stay ahead.
# m4/bison/flex are keg-only in brew and the base system shadows them with copies too old
# to build the dependency tree (m4 1.4.6, bison 2.3). Every other brew tool this build
# needs (makeinfo, help2man, msgfmt, gperf, autoconf, automake) links into brew's own bin.
# Prepended last-to-first so ACT_HOME/bin ends up highest. no dup stacking.
for p in "$(brew --prefix flex)/bin" "$(brew --prefix bison)/bin" "$(brew --prefix m4)/bin" "${ACT_HOME}/bin"; do
    case ":${PATH}:" in
        *":${p}:"*) ;;
        *) export PATH="${p}:${PATH}" ;;
    esac
done

# guard: re-sourcing runs twice per job, don't stack flags (PATH handled above)
if [ -z $ACTFLOW_ENV_LOADED ]; then
    # explicit -O3/-fPIC: CFLAGS overrides each tool's own default optimization/PIC flags
    export CFLAGS="-march=${ARCH_LEVEL} -O3 -fPIC ${CFLAGS}"
    export CXXFLAGS="-march=${ARCH_LEVEL} -O3 -fPIC ${CXXFLAGS}"
    # headerpad: the install-time pass (packaging/relocate.sh) rewrites install names
    # and rpaths with install_name_tool, which needs the load commands to have room.
    # No -rpath here: mach-o records absolute install names that the same pass rewrites.
    export LDFLAGS="-Wl,-headerpad_max_install_names ${LDFLAGS}"
    export ACTFLOW_ENV_LOADED=1
fi

echo "loaded"
