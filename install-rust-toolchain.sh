#!/bin/bash

# Default values
TOOLCHAIN_VERSION="1.56.0-dev"
if [ -z "${RUSTUP_HOME}" ]; then
    RUSTUP_HOME="${HOME}/.rustup"
fi
TOOLCHAIN_DESTINATION_DIR="${RUSTUP_HOME}/toolchains/esp"

INSTALLATION_MODE="install" # reinstall, uninstall
EXTRA_CRATES="cargo-pio espflash ldproxy"

# Process positional arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -c|--extra-crates)
      EXTRA_CRATES="$2"
      shift # past argument
      shift # past value
      ;;
    -e|--export-file)
      EXPORT_FILE="$2"
      shift # past argument
      shift # past value
      ;;
    -t|--toolchain-version)
      TOOLCHAIN_VERSION="$2"
      shift # past argument
      shift # past value
      ;;
    -d|--toolchain-destination)
      TOOLCHAIN_DESTINATION_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    -i|--installation-mode)
      INSTALLATION_MODE="$2"
      shift # past argument
      shift # past value
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

echo "Processing configuration:"
echo "--installation-mode     = ${INSTALLATION_MODE}"
echo "--export-file           = ${EXPORT_FILE}"
echo "--extra-crates          = ${EXTRA_CRATES}"
echo "--toolchain-version     = ${TOOLCHAIN_VERSION}"
echo "--toolchain-destination = ${TOOLCHAIN_DESTINATION_DIR}"

function install_rust() {
    curl https://sh.rustup.rs -sSf | bash -s -- --default-toolchain stable -y

    if [ ! -z "${CARGO_HOME}" ]; then
        source ${CARGO_HOME}/env
    else
        source ${HOME}/.cargo/env
    fi
}

function install_rust_nightly() {
    rustup toolchain install nightly
}

function install_rustfmt() {
    rustup component add rustfmt --toolchain stable
}

set -e
#set -v

# Check required tooling - rustc, rustfmt
command -v rustup || install_rust
rustup toolchain list | grep nightly || install_rust_nightly
rustfmt --version | grep stable || install_rustfmt

ARCH=`rustup show | grep "Default host" | sed -e 's/.* //'`
#ARCH="aarch64-apple-darwin"
#ARCH="x86_64-apple-darwin"
#ARCH="x86_64-unknown-linux-gnu"
#ARCH="x86_64-pc-windows-msvc"

LLVM_RELEASE="esp-12.0.1-20210914"

if [ ${ARCH} == "aarch64-apple-darwin" ]; then
    LLVM_ARCH="aarch64-apple-darwin"
    #LLVM_RELEASE="esp-12.0.1-20210823"
elif [ ${ARCH} == "x86_64-apple-darwin" ]; then
    #LLVM_ARCH="x86_64-apple-darwin"
    LLVM_ARCH="macos"
    #LLVM_RELEASE="esp-12.0.1-20210914"
elif [ ${ARCH} == "x86_64-unknown-linux-gnu" ]; then
    LLVM_ARCH="linux-amd64"
elif [ ${ARCH} == "x86_64-pc-windows-msvc" ]; then
    LLVM_ARCH="win64"
fi

echo "Processing toolchain for ${ARCH} - operation: ${INSTALLATION_MODE}"


RUST_DIST="rust-${TOOLCHAIN_VERSION}-${ARCH}"
RUST_SRC_DIST="rust-src-${TOOLCHAIN_VERSION}"
LLVM_FILE="xtensa-esp32-elf-llvm12_0_1-${LLVM_RELEASE}-${LLVM_ARCH}.tar.xz"
if [ -z "${IDF_TOOLS_PATH}" ]; then
    IDF_TOOLS_PATH="${HOME}/.espressif"
fi
IDF_TOOL_XTENSA_ELF_CLANG="${IDF_TOOLS_PATH}/tools/xtensa-esp32-elf-clang/${LLVM_RELEASE}-${ARCH}"
RUST_DIST_URL="https://github.com/esp-rs/rust-build/releases/download/v${TOOLCHAIN_VERSION}/${RUST_DIST}.tar.xz"

if [ "${INSTALLATION_MODE}" == "uninstall" ] || [ "${INSTALLATION_MODE}" == "reinstall" ] ; then
    echo "Removing:"

    echo " - ${TOOLCHAIN_DESTINATION_DIR}"
    rm -rf "${TOOLCHAIN_DESTINATION_DIR}"

    echo " - ${IDF_TOOL_XTENSA_ELF_CLANG}"
    rm -rf "${IDF_TOOL_XTENSA_ELF_CLANG}"

    if [ "${INSTALLATION_MODE}" == "uninstall" ]; then
        exit 0
    fi
fi

if [ -d "${TOOLCHAIN_DESTINATION_DIR}" ]; then
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
        curl -LO "https://github.com/esp-rs/rust-build/releases/download/v${TOOLCHAIN_VERSION}/${RUST_SRC_DIST}.tar.xz"
        tar xf ${RUST_SRC_DIST}.tar.xz
    fi
    ./${RUST_SRC_DIST}/install.sh --destdir=${TOOLCHAIN_DESTINATION_DIR} --prefix="" --without=rust-docs
fi

echo -n "* installing ${IDF_TOOL_XTENSA_ELF_CLANG} - "
if [ ! -d ${IDF_TOOL_XTENSA_ELF_CLANG} ]; then
    if [ ! -f "${LLVM_FILE}" ]; then
        curl -LO "https://github.com/espressif/llvm-project/releases/download/${LLVM_RELEASE}/${LLVM_FILE}"
    fi
    mkdir -p "${IDF_TOOL_XTENSA_ELF_CLANG}"
    if [ ${ARCH} == "x86_64-apple-darwin" ] || [ ${ARCH} == "aarch64-apple-darwin" ] || [ ${ARCH} == "x86_64-unknown-linux-gnu" ] ; then
        tar xf ${LLVM_FILE} -C "${IDF_TOOL_XTENSA_ELF_CLANG}" --strip-components=1
    else
        tar xf ${LLVM_FILE} -C "${IDF_TOOL_XTENSA_ELF_CLANG}"
    fi
    echo "done"
else
    echo "already installed"
fi

if [[ ! -z "${EXTRA_CRATES}" ]]; then
    echo "Installing additional extra crates: ${EXTRA_CRATES}"
    cargo install ${EXTRA_CRATES}
fi

echo "Add following command to ~/.zshrc"
echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:\$PATH\"
echo export LIBCLANG_PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/lib/\"

# Store export instructions in the file
if [[ ! -z "${EXPORT_FILE}" ]]; then
    echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:\$PATH\" > "${EXPORT_FILE}"
    echo export LIBCLANG_PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/lib/\" >> "${EXPORT_FILE}"
fi
