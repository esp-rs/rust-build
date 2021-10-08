#!/bin/bash

function install_rust() {
    curl https://sh.rustup.rs -sSf | bash -s -- --profile minimal --default-toolchain nightly -y
    if [ ! -z "${CARGO_HOME}" ]; then
        source ${CARGO_HOME}/env
    else
        source ${HOME}/.cargo/env
    fi
}

set -e
#set -v

which rustc || install_rust
rustup toolchain list | grep nightly || install_rust 

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
    #LLVM_RELEASE="esp-12.0.1-20210914"
elif [ ${ARCH} == "x86_64-unknown-linux-gnu" ]; then
    LLVM_ARCH="linux-amd64"
elif [ ${ARCH} == "x86_64-pc-windows-msvc" ]; then
    LLVM_ARCH="win64"
fi

echo "Installation of toolchain for ${ARCH}"


VERSION="1.55.0-dev"
RUST_DIST="rust-${VERSION}-${ARCH}"
RUST_SRC_DIST="rust-src-${VERSION}"
if [ -z "${RUSTUP_HOME}" ]; then
    RUSTUP_HOME="${HOME}/.rustup"
fi
TOOLCHAIN_DESTINATION_DIR="${RUSTUP_HOME}/toolchains/esp"
LLVM_FILE="xtensa-esp32-elf-llvm12_0_1-${LLVM_RELEASE}-${LLVM_ARCH}.tar.xz"
if [ -z "${IDF_TOOLS_PATH}" ]; then
    IDF_TOOLS_PATH="${HOME}/.espressif"
fi
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

echo -n "* installing ${IDF_TOOL_XTENSA_ELF_CLANG} - "
if [ ! -d ${IDF_TOOL_XTENSA_ELF_CLANG} ]; then
    curl -LO "https://github.com/espressif/llvm-project/releases/download/${LLVM_RELEASE}/${LLVM_FILE}"
    mkdir -p "${IDF_TOOL_XTENSA_ELF_CLANG}"
    if [ ${ARCH} == "aarch64-apple-darwin" ] || [ ${ARCH} == "x86_64-unknown-linux-gnu" ] ; then
        tar xf ${LLVM_FILE} -C "${IDF_TOOL_XTENSA_ELF_CLANG}" --strip-components=1
    else
        tar xf ${LLVM_FILE} -C "${IDF_TOOL_XTENSA_ELF_CLANG}"
    fi
    echo "done"
else
    echo "already installed"
fi

echo "Add following command to ~/.zshrc"
echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:\$PATH\"

# Store export instructions in the file
if [[ "$1" == "--export-file" ]]; then
    echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:\$PATH\" >> "$2"
fi
