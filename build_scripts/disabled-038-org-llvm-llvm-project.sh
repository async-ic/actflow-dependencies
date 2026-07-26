#!/bin/bash

echo "#############################"
echo "#build llvm"

cd $EDA_SRCDIR/org-llvm-llvm-project
cp llvm/LICENSE.TXT $ACT_HOME/license/LICENSE_org-llvm-llvm-project

  #echo "no CI => building, this will take a long time"
  if [ ! -d build ]; then
	mkdir build
  fi
  cd $EDA_SRCDIR/org-llvm-llvm-project/build
  export LD_LIBRARY_PATH=$ACT_HOME/lib
  cmake \
  -D LLVM_ENABLE_RTTI=ON \
  -D CMAKE_INSTALL_PREFIX=$ACT_HOME \
  -D CMAKE_INCLUDE_PATH=$ACT_HOME/include \
  -D CMAKE_LIBRARY_PATH=$ACT_HOME/lib \
  -D CMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
  -D CMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN/../lib' -L${ACT_HOME}/lib" \
  -D LLVM_INCLUDE_BENCHMARKS=OFF \
  -D CMAKE_BUILD_TYPE=Release \
  -D LLVM_BUILD_LLVM_DYLIB=ON \
  -D LLVM_INCLUDE_TESTS=OFF \
  -D LLVM_TARGETS_TO_BUILD="host" \
  -D LLVM_ENABLE_PROJECTS="" \
  -D LLVM_ENABLE_RUNTIMES="" \
  -D LLVM_INCLUDE_EXAMPLES=OFF \
  -D LLVM_INCLUDE_TOOLS=OFF \
  -G "Unix Makefiles" \
  ../llvm
  make -j4
cd $EDA_SRCDIR/org-llvm-llvm-project/build
make install
unset LD_LIBRARY_PATH

