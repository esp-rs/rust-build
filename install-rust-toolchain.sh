#!/usr/bin/env bash

# Default values
TOOLCHAIN_VERSION="1.60.0.1"
if [ -z "${RUSTUP_HOME}" ]; then
    RUSTUP_HOME="${HOME}/.rustup"
fi
TOOLCHAIN_DESTINATION_DIR="${RUSTUP_HOME}/toolchains/esp"

RUSTC_MINIMAL_MINOR_VERSION="55"
INSTALLATION_MODE="install" # reinstall, uninstall
LLVM_VERSION="esp-14.0.0-20220415"
CLEAR_DOWNLOAD_CACHE="NO"
EXTRA_CRATES="ldproxy cargo-espflash"

display_help() {
  echo "Usage: install-rust-toolchain.sh <arguments>"
  echo "Arguments: "
  echo "-e|--extra-crates               Extra crates to install. Defaults to: ldproxy cargo-espflash"
  echo "-d|--toolchain-destination      Toolchain instalation folder."
  echo "-f|--export-file                Destination of the export file generated."
  echo "-c|--cargo-home                 Cargo path"
  echo "-i|--installation-mode          Installation mode: [install, reinstall, uninstall]. Defaults to: insatll"
  echo "-l|--llvm-version               LLVM version"
  echo "-r|--rustup-home                Path to .rustup"
  echo "-t|--toolchain-version          Rust toolchain version"
  echo "-x|--clear-cache                Removes cached distribution files"
}

# Process positional arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -h|--help)
      display_help
      exit 1
      ;;
    -e|--extra-crates)
      EXTRA_CRATES="$2"
      shift # past argument
      shift # past value
      ;;
    -d|--toolchain-destination)
      TOOLCHAIN_DESTINATION_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    -f|--export-file)
      EXPORT_FILE="$2"
      shift # past argument
      shift # past value
      ;;
    -o|--cargo-home)
      CARGO_HOME="$2"
      shift # past argument
      shift # past value
      ;;
    -i|--installation-mode)
      INSTALLATION_MODE="$2"
      shift # past argument
      shift # past value
      ;;
    -l|--llvm-version)
      LLVM_VERSION="$2"
      shift # past argument
      shift # past value
      ;;
    -r|--rustup-home)
      RUSTUP_HOME="$2"
      shift # past argument
      shift # past value
      ;;
    -t|--toolchain-version)
      TOOLCHAIN_VERSION="$2"
      shift # past argument
      shift # past value
      ;;
    -x|--clear-cache)
      CLEAR_DOWNLOAD_CACHE="$2"
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
echo "--cargo-home            = ${CARGO_HOME}"
echo "--clear-cache           = ${CLEAR_DOWNLOAD_CACHE}"
echo "--export-file           = ${EXPORT_FILE}"
echo "--extra-crates          = ${EXTRA_CRATES}"
echo "--installation-mode     = ${INSTALLATION_MODE}"
echo "--llvm-version          = ${LLVM_VERSION}"
echo "--rustup-home           = ${RUSTUP_HOME}"
echo "--toolchain-version     = ${TOOLCHAIN_VERSION}"
echo "--toolchain-destination = ${TOOLCHAIN_DESTINATION_DIR}"

function install_rust() {
    curl https://sh.rustup.rs -sSf | bash -s -- --default-toolchain stable -y
}

function source_cargo() {
    if [ -e "${HOME}/.cargo/env" ]; then
        source "${HOME}/.cargo/env"
        export CARGO_HOME="${HOME}/.cargo/"
    else
        if [ -n "${CARGO_HOME}" ] && [ -e "${CARGO_HOME}/env" ]; then
            source ${CARGO_HOME}/env
        else
	    echo "Warning: Unable to source .cargo/env"
            export CARGO_HOME="${HOME}/.cargo/"
        fi
    fi
}

function install_rust_toolchain() {
    rustup toolchain install $1
}

function install_rustfmt() {
    rustup component add rustfmt --toolchain stable
    rustup component add rustfmt --toolchain nightly
}

function clear_download_cache() {
  echo "Removing cached dist files:"
  echo " - ${RUST_DIST}"
  rm -rf "${RUST_DIST}"

  echo " - ${RUST_DIST}.tar.xz"
  rm -f "${RUST_DIST}.tar.xz"

  echo " - ${RUST_SRC_DIST}"
  rm -rf "${RUST_SRC_DIST}"

  echo " - ${RUST_SRC_DIST}.tar.xz"
  rm -f "${RUST_SRC_DIST}.tar.xz"

  echo " - ${LLVM_FILE}"
  rm -f "${LLVM_FILE}"
}

set -e
#set -v

# Check required tooling - rustc, rustfmt
command -v rustup || install_rust

source_cargo

# Check minimal rustc version
RUSTC_MINOR_VERSION=`rustc --version | sed -e 's/^rustc 1\.\([^.]*\).*/\1/'`
if [ "${RUSTC_MINOR_VERSION}" -lt "${RUSTC_MINIMAL_MINOR_VERSION}" ]; then
    echo "rustc version is too low, requires 1.${RUSTC_MINIMAL_MINOR_VERSION}"
    echo "calling rustup"
    install_rust
fi

rustup toolchain list | grep stable || install_rust_toolchain stable
rustup toolchain list | grep nightly || install_rust_toolchain nightly
install_rustfmt

ARCH=`rustup show | grep "Default host" | sed -e 's/.* //'`
#ARCH="aarch64-apple-darwin"
#ARCH="aarch64-unknown-linux-gnu"
#ARCH="x86_64-apple-darwin"
#ARCH="x86_64-unknown-linux-gnu"
#ARCH="x86_64-pc-windows-msvc"
LLVM_DIST_MIRROR="https://github.com/espressif/llvm-project/releases/download/${LLVM_VERSION}"

if [ ${ARCH} == "aarch64-apple-darwin" ]; then
    LLVM_ARCH="${ARCH}"
    ESPFLASH_URL=""
    ESPFLASH_BIN=""
    # LLVM artifact is stored as part of Rust release
    LLVM_DIST_MIRROR="https://github.com/esp-rs/rust-build/releases/download/v${TOOLCHAIN_VERSION}"
elif [ ${ARCH} == "x86_64-apple-darwin" ]; then
    LLVM_ARCH="macos"
    ESPFLASH_URL=""
    ESPFLASH_BIN=""
elif [ ${ARCH} == "x86_64-unknown-linux-gnu" ]; then
    LLVM_ARCH="linux-amd64"
    ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash"
    ESPFLASH_BIN="${CARGO_HOME}/bin/cargo-espflash"
elif [ ${ARCH} == "aarch64-unknown-linux-gnu" ]; then
    LLVM_ARCH="${ARCH}"
    ESPFLASH_URL=""
    ESPFLASH_BIN=""
    # LLVM artifact is stored as part of Rust release
    LLVM_DIST_MIRROR="https://github.com/esp-rs/rust-build/releases/download/v${TOOLCHAIN_VERSION}"
elif [ ${ARCH} == "x86_64-pc-windows-msvc" ]; then
    LLVM_ARCH="win64"
    ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash.exe"
    ESPFLASH_BIN="${CARGO_HOME}/bin/cargo-espflash.exe"
fi

echo "Processing toolchain for ${ARCH} - operation: ${INSTALLATION_MODE}"


RUST_DIST="rust-${TOOLCHAIN_VERSION}-${ARCH}"
RUST_SRC_DIST="rust-src-${TOOLCHAIN_VERSION}"
LLVM_ARTIFACT_VERSION=`echo ${LLVM_VERSION} | sed -e 's/.*esp-//g' -e 's/-.*//g' -e 's/\./_/g'`
LLVM_FILE="xtensa-esp32-elf-llvm${LLVM_ARTIFACT_VERSION}-${LLVM_VERSION}-${LLVM_ARCH}.tar.xz"
LLVM_DIST_URL="${LLVM_DIST_MIRROR}/${LLVM_FILE}"
if [ -z "${IDF_TOOLS_PATH}" ]; then
    IDF_TOOLS_PATH="${HOME}/.espressif"
fi
IDF_TOOL_XTENSA_ELF_CLANG="${IDF_TOOLS_PATH}/tools/xtensa-esp32-elf-clang/${LLVM_VERSION}-${ARCH}"
RUST_DIST_URL="https://github.com/esp-rs/rust-build/releases/download/v${TOOLCHAIN_VERSION}/${RUST_DIST}.tar.xz"

if [ "${INSTALLATION_MODE}" == "uninstall" ] || [ "${INSTALLATION_MODE}" == "reinstall" ] ; then
    echo "Removing:"

    echo " - ${TOOLCHAIN_DESTINATION_DIR}"
    rm -rf "${TOOLCHAIN_DESTINATION_DIR}"

    echo " - ${IDF_TOOL_XTENSA_ELF_CLANG}"
    rm -rf "${IDF_TOOL_XTENSA_ELF_CLANG}"

    if [ "${CLEAR_DOWNLOAD_CACHE}" == "YES" ]; then
        clear_download_cache
    fi

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
        mkdir -p ${RUST_DIST}
        tar xf ${RUST_DIST}.tar.xz --strip-components=1 -C ${RUST_DIST}
    fi
    ./${RUST_DIST}/install.sh --destdir=${TOOLCHAIN_DESTINATION_DIR} --prefix="" --without=rust-docs

    if [ ! -f ${RUST_SRC_DIST}.tar.xz ]; then
        curl -LO "https://github.com/esp-rs/rust-build/releases/download/v${TOOLCHAIN_VERSION}/${RUST_SRC_DIST}.tar.xz"
        mkdir -p ${RUST_SRC_DIST}
        tar xf ${RUST_SRC_DIST}.tar.xz --strip-components=1 -C ${RUST_SRC_DIST}
    fi
    ./${RUST_SRC_DIST}/install.sh --destdir=${TOOLCHAIN_DESTINATION_DIR} --prefix="" --without=rust-docs
fi

echo "* installing ${IDF_TOOL_XTENSA_ELF_CLANG} "
if [ ! -d ${IDF_TOOL_XTENSA_ELF_CLANG} ]; then
    if [ ! -f "${LLVM_FILE}" ]; then
        echo "** Downloading ${LLVM_DIST_URL}"
        curl -LO "${LLVM_DIST_URL}"
    fi
    mkdir -p "${IDF_TOOL_XTENSA_ELF_CLANG}"
    tar xf ${LLVM_FILE} -C "${IDF_TOOL_XTENSA_ELF_CLANG}" --strip-components=1
    echo "done"
else
    echo "already installed"
fi

if [[ ! -z "${EXTRA_CRATES}" ]]; then
  for CRATE in ${EXTRA_CRATES}; do
    echo "Installing additional extra crate: ${CRATE}"
    if [ "${CRATE}" = "cargo-espflash" ] && [[ ! -z "${ESPFLASH_URL}" ]]; then
      if [[ ! -e "${ESPFLASH_BIN}" ]]; then
        curl -L "${ESPFLASH_URL}" -o "${ESPFLASH_BIN}"
        chmod u+x "${ESPFLASH_BIN}"
      fi
      echo "Using cargo-espflash binary release"
    else
      cargo install ${CRATE}
    fi
  done
fi

if [ "${CLEAR_DOWNLOAD_CACHE}" == "YES" ]; then
    clear_download_cache
fi

PROFILE_NAME="your default shell"
if grep -q "zsh" <<< "$SHELL"; then
  PROFILE_NAME=~/.zshrc
elif grep -q "bash" <<< "$SHELL"; then
  PROFILE_NAME=~/.bashrc
fi
echo "Add following command to $PROFILE_NAME"
echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:\$PATH\"
echo export LIBCLANG_PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/lib/\"
# Workaround of https://github.com/espressif/esp-idf/issues/7910
echo export PIP_USER="no"

# Store export instructions in the file
if [[ ! -z "${EXPORT_FILE}" ]]; then
    echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:\$PATH\" > "${EXPORT_FILE}"
    echo export LIBCLANG_PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/lib/\" >> "${EXPORT_FILE}"
    echo export PIP_USER="no" >> "${EXPORT_FILE}"
fi

