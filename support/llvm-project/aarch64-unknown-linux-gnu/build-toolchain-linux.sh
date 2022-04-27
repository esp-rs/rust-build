#!/usr/bin/env bash

set -e

AVAILABLE_MEMORY=`awk '/MemAvailable/ { printf "%.0f \n", $2/1024 }' /proc/meminfo`
if [ "$AVAILABLE_MEMORY" -lt "6000" ]; then 
    echo "Insufficient memory for -j8 build. Increase memory or decrease number of processes for cmake"
    exit 1
fi

git clone --recursive --depth 1 https://github.com/espressif/llvm-project.git

# Clean up collision directory
CLANG_XTENSA_TOOLCHAIN=${HOME}/.espressif/tools/xtensa-clang-toolchain
rm -rf ${CLANG_XTENSA_TOOLCHAIN}
mkdir -p ${CLANG_XTENSA_TOOLCHAIN}

export INSTALLPREFIX=${HOME}/xtensa-esp32-elf-clang
rm -rf ${INSTALLPREFIX}
mkdir ${INSTALLPREFIX}


cd llvm-project
cp ../clangwrap.cpp ${INSTALLPREFIX}


mkdir build
cd build
cmake ../llvm -DLLVM_TARGETS_TO_BUILD="AArch64" -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=Xtensa -DCMAKE_BUILD_TYPE=Release -DLLVM_EXTERNAL_CLANG_SOURCE_DIR=../clang -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;"
cmake --build . -- -j8
rm ../llvm/test/tools/llvm-ar/error-opening-permission.test
rm ../llvm/test/tools/llvm-elfabi/fail-file-write.test

if cmake --build . --target check-llvm ; then
    echo "LLVM tests passed"
else
    echo "LLVM tests failed"
    exit 1
fi

cd ..

g++ -std=c++11 clangwrap.cpp -o ${CLANG_XTENSA_TOOLCHAIN}/bin/xtensa-esp32-elf-clang
cp ${CLANG_XTENSA_TOOLCHAIN}/bin/xtensa-esp32-elf-clang ${CLANG_XTENSA_TOOLCHAIN}/bin/xtensa-esp32-elf-clang++

mv build/bin/clang ${CLANG_XTENSA_TOOLCHAIN}/bin/
mv build/bin/clang++ ${CLANG_XTENSA_TOOLCHAIN}/bin/
mv build/bin/clang-14 ${CLANG_XTENSA_TOOLCHAIN}/bin/
mv build/bin/clang-tidy ${CLANG_XTENSA_TOOLCHAIN}/bin/
mv build/bin/clang-format ${CLANG_XTENSA_TOOLCHAIN}/bin/
mv build/bin/scan-build ${CLANG_XTENSA_TOOLCHAIN}/bin/
mv build/bin/llvm-config ${CLANG_XTENSA_TOOLCHAIN}/bin/
mv build/libexec/* ${CLANG_XTENSA_TOOLCHAIN}/libexec/
mv build/lib/clang ${CLANG_XTENSA_TOOLCHAIN}/lib/
mv build/lib/libclang.* ${CLANG_XTENSA_TOOLCHAIN}/lib/
#mv xtensa-esp32-elf-clang* ${CLANG_XTENSA_TOOLCHAIN}/bin/

cd ..
tar cJf xtensa-esp32-elf-llvm14_0_0-esp-14.0.0-20220415-aarch64-unknown-linux-gnu.tar.xz xtensa-esp32-elf-clang


