#!/usr/bin/bash

# Clean up collision directory
XTENSA_CLANG_TOOLCHAIN=${HOME}/.espressif/tools/xtensa-clang-toolchain
rm -rf ${XTENSA_CLANG_TOOLCHAIN}
mkdir -p ${XTENSA_CLANG_TOOLCHAIN}

export INSTALLPREFIX=${HOME}/xtensa-esp32-elf-clang
rm -rf ${INSTALLPREFIX}
mkdir ${INSTALLPREFIX}


cd llvm-project
cp clangwrap.cpp ${INSTALLPREFIX}
../build-toolchain-macos-m1.sh

cd ..
tar cJf xtensa-esp32-elf-llvm14_0_0-esp-14.0.0-20220415-aarch64-apple-darwin.tar.xz xtensa-esp32-elf-clang

