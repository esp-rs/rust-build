#!/usr/bin/env bash
#
# Build and install Clang/LLVM, using `gcc`.
#
# You only need to run this if your distribution does not provide
# clang - or if you want to build your own version from a recent
# source tree.
#
if [ -z "$INSTALLPREFIX" ]; then
  INSTALLPREFIX="/usr/local"
fi

set -e
set -v

if [ -z "$1" ]; then
  CLANG_XTENSA_TOOLCHAIN="${INSTALLPREFIX}"
else
  CLANG_XTENSA_TOOLCHAIN="$1"
fi

function build() {
  stage=$1
  mkdir -p $stage
  pushd $stage &>/dev/null
  cmake -G Ninja ../llvm \
    -DCMAKE_INSTALL_PREFIX=$INSTALLPREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=1 \
    -DLLVM_TARGETS_TO_BUILD="AArch64" \
    -DLLVM_EXTERNAL_CLANG_SOURCE_DIR=$PWD/../clang
  ninja -j 8
  echo "Install clang"
  ninja install
  cp ./bin/llvm-tblgen ${INSTALLPREFIX}/bin/
  cp ./bin/clang-tblgen ${INSTALLPREFIX}/bin/
  cp ./bin/llvm-config ${INSTALLPREFIX}/bin/
  echo ""
  echo "Done!"
  echo ""
  popd &>/dev/null
}

build build
#
#OSXCROSS_TAR=osxcross-master-26ebac2.tar.bz2
#wget --continue --no-verbose "https://dl.espressif.com/dl/toolchains/${OSXCROSS_TAR}"
#mkdir -v "osxcross" && tar xf "${OSXCROSS_TAR}" -C "osxcross" --strip-components 1
#
#cd osxcross/tarballs/
#wget --continue --no-verbose https://dl.espressif.com/dl/toolchains/MacOSX11.3.sdk.tar.xz
#
#cd ..
#
#export UNATTENDED=1
#./build.sh
#export ENABLE_COMPILER_RT_INSTALL=1
#./build_compiler_rt.sh
#cd ..
#
#export OSXCROSS_PATH=$PWD/osxcross/
#export PATH=$OSXCROSS_PATH/target/bin:$PATH

#Cross compile clang for MacOS
mkdir -p build_xtensa
cd build_xtensa
cmake -G Ninja $PWD/../llvm \
  -DCMAKE_CROSSCOMPILING=True \
  -DCMAKE_SYSTEM_NAME=Darwin \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 \
  -DCMAKE_SYSTEM_VERSION=10.9 \
  -DLLVM_TARGETS_TO_BUILD="AArch64" \
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="Xtensa" \
  -DLLVM_DEFAULT_TARGET_TRIPLE="aarch64-apple-darwin20.4" \
  -DLLVM_TARGET_ARCH="AArch64" \
  -DLLVM_EXTERNAL_CLANG_SOURCE_DIR=$PWD/../clang \
  -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_TABLEGEN=${INSTALLPREFIX}/bin/llvm-tblgen \
  -DCLANG_TABLEGEN=${INSTALLPREFIX}/bin/clang-tblgen \
  -DLLVM_CONFIG_PATH=${INSTALLPREFIX}/bin/llvm-config \
  -DLLVM_ENABLE_LIBXML2=OFF

ninja -j 8

cd ..

#Assemble xtensa clang toolchain for MacOS
clang++ -std=c++11 clangwrap.cpp -o ${CLANG_XTENSA_TOOLCHAIN}/bin/xtensa-esp32-elf-clang
cp ${CLANG_XTENSA_TOOLCHAIN}/bin/xtensa-esp32-elf-clang ${CLANG_XTENSA_TOOLCHAIN}/bin/xtensa-esp32-elf-clang++

mv build_xtensa/bin/clang ${CLANG_XTENSA_TOOLCHAIN}/bin/
mv build_xtensa/bin/clang++ ${CLANG_XTENSA_TOOLCHAIN}/bin/
mv build_xtensa/bin/clang-12 ${CLANG_XTENSA_TOOLCHAIN}/bin/
mv build_xtensa/bin/clang-tidy ${CLANG_XTENSA_TOOLCHAIN}/bin/
mv build_xtensa/bin/clang-format ${CLANG_XTENSA_TOOLCHAIN}/bin/
mv build_xtensa/bin/scan-build ${CLANG_XTENSA_TOOLCHAIN}/bin/
mv build_xtensa/bin/llvm-config ${CLANG_XTENSA_TOOLCHAIN}/bin/
mv build_xtensa/libexec/* ${CLANG_XTENSA_TOOLCHAIN}/libexec/
mv build_xtensa/lib/clang ${CLANG_XTENSA_TOOLCHAIN}/lib/
mv build_xtensa/lib/libclang.* ${CLANG_XTENSA_TOOLCHAIN}/lib/
