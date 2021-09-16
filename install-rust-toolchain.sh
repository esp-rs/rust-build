#!/bin/bash

set -e
set -v

ARCH=`rustup show | grep "Default host" | sed -e 's/.* //'`
#ARCH="aarch64-apple-darwin"
#ARCH="x86_64-apple-darwin"
#ARCH="x86_64-unknown-linux-gnu"
#ARCH="x86_64-pc-windows-msvc"

LLVM_RELEASE="esp-12.0.1-20210823"

if [ ${ARCH} == "aarch64-apple-darwin" ]; then
    LLVM_ARCH="aarch64-apple-darwin"
elif [ ${ARCH} == "x86_64-apple-darwin" ]; then
    #LLVM_ARCH="x86_64-apple-darwin"
    LLVM_ARCH="macos"
    LLVM_RELEASE="esp-12.0.1-20210914"
elif [ ${ARCH} == "x86_64-unknown-linux-gnu" ]; then
    LLVM_ARCH="linux-amd64"
elif [ ${ARCH} == "x86_64-pc-windows-msvc" ]; then
    LLVM_ARCH="win64"
fi

echo "Installation of toolchain for ${ARCH}"

rustup toolchain list | grep nightly || rustup toolchain install nightly

VERSION="1.55.0-dev"
RUST_DIST="rust-${VERSION}-${ARCH}"
RUST_SRC_DIST="rust-src-${VERSION}"
TOOLCHAIN_DESTINATION_DIR="$HOME/.rustup/toolchains/esp"
LLVM_FILE="xtensa-esp32-elf-llvm12_0_1-${LLVM_RELEASE}-${LLVM_ARCH}.tar.xz"
IDF_TOOLS_PATH="$HOME/.espressif"
IDF_TOOL_XTENSA_ELF_CLANG="${IDF_TOOLS_PATH}/tools/xtensa-esp32-elf-clang/${LLVM_RELEASE}-${ARCH}"
RUST_DIST_URL="https://github.com/esp-rs/rust-build/releases/download/v${VERSION}/${RUST_DIST}.tar.xz"

if [ -d ${TOOLCHAIN_DESTINATION_DIR} ]; then
    echo "Previous installation of toolchain exist in: ${TOOLCHAIN_DESTINATION_DIR}"
    echo "Please, remove the directory before new installation."
    exit 1
fi


if [ ! -d ${TOOLCHAIN_DESTINATION_DIR} ]; then
    mkdir -p ${TOOLCHAIN_DESTINATION_DIR}
    if [ ! -f ${RUST_DIST}.tar.xz ]; then
        echo "** downloading: ${RUST_DIST_URL}"
        curl -LO "${RUST_DIST_URL}"
        tar xf ${RUST_DIST}.tar.xz
    fi
    ./${RUST_DIST}/install.sh --destdir=${TOOLCHAIN_DESTINATION_DIR} --prefix="" --without=rust-docs

    if [ ! -f ${RUST_SRC_DIST}.tar.xz ]; then
        curl -LO "https://github.com/esp-rs/rust-build/releases/download/v${VERSION}/${RUST_SRC_DIST}.tar.xz"
        tar xf ${RUST_SRC_DIST}.tar.xz
    fi
    ./${RUST_SRC_DIST}/install.sh --destdir=${TOOLCHAIN_DESTINATION_DIR} --prefix="" --without=rust-docs
fi

rustup default esp

echo -n "* installing ${IDF_TOOL_XTENSA_ELF_CLANG} - "
if [ ! -d ${IDF_TOOL_XTENSA_ELF_CLANG} ]; then
    curl -LO "https://github.com/espressif/llvm-project/releases/download/${LLVM_RELEASE}/${LLVM_FILE}"
    mkdir -p `dirname "${IDF_TOOL_XTENSA_ELF_CLANG}"`
    tar xf ${LLVM_FILE} -C "${IDF_TOOL_XTENSA_ELF_CLANG}"
    echo "done"
else
    echo "already installed"
fi

echo "Add following command to ~/.zshrc"
echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:\$PATH\"


