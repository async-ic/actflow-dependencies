#!/bin/bash
#
# Builds LLVM into the isolated sub-prefix $ACT_HOME/llvm. Disabled by default;
# required only for the fluid testing package (fluid/CMakeLists.txt:
# find_package(LLVM REQUIRED CONFIG)).
#
# Findings (empirically verified, building the real fluid tree):
# - fluid links NO LLVM lib: libfluid.so is an `opt -load` pass plugin, and its
#   declared components (support/core/irreader) are computed but never linked;
#   the build needs only LLVM headers + LLVMConfig.cmake. opt + clang are built
#   and installed too (LLVM_DISTRIBUTION_COMPONENTS, no other LLVM tools) to RUN
#   the pass: test0/workloads do `clang -emit-llvm` + `opt -load libfluid.so`.
# - libc++/libc++abi/libunwind runtimes are bundled (distribution cxx;cxxabi;unwind)
#   so the fluid cxx reference builds with `clang++ -stdlib=libc++`: clang-14 is too
#   old to parse the shipped gcc16 libstdc++, its matched libc++-14 compiles fine.
#   cxx-headers is a runtimes sub-component, not a runtime_name (cxx/cxxabi/unwind
#   auto-get top-level targets), so it must go in LLVM_RUNTIME_DISTRIBUTION_COMPONENTS
#   for an install-cxx-headers forwarding target; else install-distribution omits the
#   headers. Build via `make install-distribution` ONLY, never `make distribution`: the
#   latter depends on the raw `cxx-headers` target, an INTERFACE lib with no make rule
#   ("No rule to make target 'cxx-headers'"). install-<comp> builds its deps first, but
#   the runtime install-* targets race under -j (see `make runtimes` below).
# - Version ceiling: fluid builds unmodified only up to LLVM 14 (14.0.6 OK;
#   12/11 OK; 13 is a hole: ConstantAggregateZero::getNumElements). 15+ break on
#   the new llvm::json vs nlohmann json clash (`using namespace llvm`), plus @16
#   StringRef::equals removed + missing <cmath>. => pin submodule llvmorg-14.0.6.
# - Functional ceiling is LLVM 16 even with source fixes: `opt`'s legacy pass
#   manager (needed by `opt -load libfluid.so -pipelink`) was removed in LLVM 17.
# - dylib disabled (LLVM_BUILD_LLVM_DYLIB=OFF): nothing links libLLVM; opt/clang
#   link the static libs.
# - Isolation: installs under $ACT_HOME/llvm, NOT $ACT_HOME/bin, so this outdated
#   clang is never on the build PATH (only $ACT_HOME/bin is) and no other dep /
#   actflow build can pick it up. Consumers opt in via -DLLVM_DIR; runtime adds
#   $ACT_HOME/llvm/bin to PATH. rpath fixed by packaging/004-build_testing.sh's ELF pass.
# - gcc16: LLVM 14 headers miss <cstdint> (uintNN_t) => -include cstdint.
# - make || exit 1: trailing `unset` (exit 0) else masks failure, ships llvm-less pkg.
# - compiler-rt (builtins+crt) is built standalone after install-distribution so the
#   bundled clang is self-contained: it links clang_rt.crtbegin/crtend + libclang_rt.
#   builtins instead of gcc crtbegin.o/-lgcc, and libunwind instead of libgcc_s. The
#   fluid test targets (Ubuntu/Debian/Fedora) install libc + binutils but NO gcc, so a
#   gcc fallback fails "cannot find crtbegin.o / -lgcc". Installed into clang's resource
#   dir (lib/linux) where clang finds it via --rtlib=compiler-rt.

echo "#############################"
echo "#build llvm"

cd $EDA_SRC/org-llvm-llvm-project || exit 1
cp llvm/LICENSE.TXT $ACT_HOME/license/LICENSE_org-llvm-llvm-project

  #echo "no CI => building, this will take a long time"
  if [ ! -d build ]; then
	mkdir build
  fi
  cd $EDA_SRC/org-llvm-llvm-project/build || exit 1
  export LD_LIBRARY_PATH=$ACT_HOME/lib
  cmake \
  -D LLVM_ENABLE_RTTI=ON \
  -D CMAKE_INSTALL_PREFIX=$ACT_HOME/llvm \
  -D CMAKE_INCLUDE_PATH=$ACT_HOME/include \
  -D CMAKE_LIBRARY_PATH=$ACT_HOME/lib \
  -D CMAKE_CXX_FLAGS="${CXXFLAGS} -include cstdint" \
  -D CMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
  -D CMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
  -D LLVM_INCLUDE_BENCHMARKS=OFF \
  -D CMAKE_BUILD_TYPE=Release \
  -D LLVM_BUILD_LLVM_DYLIB=OFF \
  -D LLVM_INCLUDE_TESTS=OFF \
  -D LLVM_TARGETS_TO_BUILD="host" \
  -D LLVM_ENABLE_PROJECTS="clang" \
  -D LLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
  -D LLVM_INCLUDE_EXAMPLES=OFF \
  -D LLVM_INCLUDE_TOOLS=ON \
  -D LLVM_DISTRIBUTION_COMPONENTS="opt;clang;clang-resource-headers;llvm-config;llvm-headers;cmake-exports;cxx;cxxabi;unwind" \
  -D LLVM_RUNTIME_DISTRIBUTION_COMPONENTS="cxx-headers" \
  -G "Unix Makefiles" \
  ../llvm
  # runtimes in ONE sub-make first, then install so -j4 runs
  # up to 4 makes -> race condition.
  make -j4 runtimes || exit 1
  make -j4 install-distribution || exit 1

  # compiler-rt builtins+crt, built by the just-installed clang, into its resource dir.
  # Only builtins+crt (no sanitizers/profile/etc); COMPILER_*_WORKS bypass the C++/link
  # probes (clang-14 can't link the gcc16 libstdc++ default, and builtins/crt are C/asm
  # objects only, never linked here). RESDIR = <prefix>/lib/clang/<ver>.
  CLANG_RT=$ACT_HOME/llvm/bin/clang
  RESDIR=$("$CLANG_RT" -print-resource-dir)
  mkdir -p $EDA_SRC/org-llvm-llvm-project/build-compiler-rt
  cd $EDA_SRC/org-llvm-llvm-project/build-compiler-rt || exit 1
  cmake \
  -D CMAKE_C_COMPILER="$CLANG_RT" \
  -D CMAKE_CXX_COMPILER="$ACT_HOME/llvm/bin/clang++" \
  -D CMAKE_ASM_COMPILER="$CLANG_RT" \
  -D CMAKE_C_COMPILER_WORKS=1 \
  -D CMAKE_CXX_COMPILER_WORKS=1 \
  -D CMAKE_ASM_COMPILER_WORKS=1 \
  -D CMAKE_C_COMPILER_TARGET=$("$CLANG_RT" -print-target-triple) \
  -D CMAKE_BUILD_TYPE=Release \
  -D LLVM_CONFIG_PATH=$ACT_HOME/llvm/bin/llvm-config \
  -D COMPILER_RT_DEFAULT_TARGET_ONLY=ON \
  -D COMPILER_RT_BUILD_BUILTINS=ON \
  -D COMPILER_RT_BUILD_CRT=ON \
  -D COMPILER_RT_BUILD_SANITIZERS=OFF \
  -D COMPILER_RT_BUILD_XRAY=OFF \
  -D COMPILER_RT_BUILD_LIBFUZZER=OFF \
  -D COMPILER_RT_BUILD_PROFILE=OFF \
  -D COMPILER_RT_BUILD_MEMPROF=OFF \
  -D COMPILER_RT_BUILD_ORC=OFF \
  -D COMPILER_RT_INCLUDE_TESTS=OFF \
  -D CMAKE_INSTALL_PREFIX="$RESDIR" \
  -G "Unix Makefiles" \
  ../compiler-rt
  make -j4 builtins crt || exit 1
  make install-builtins install-crt || exit 1
unset LD_LIBRARY_PATH

