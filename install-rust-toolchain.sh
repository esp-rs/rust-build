#!/usr/bin/env bash

set -e
#set -v

# Default values
TOOLCHAIN_VERSION="1.61.0.0"
if [ -z "${RUSTUP_HOME}" ]; then
    RUSTUP_HOME="${HOME}/.rustup"
fi
TOOLCHAIN_DESTINATION_DIR="${RUSTUP_HOME}/toolchains/esp"
BUILD_TARGET="esp32,esp32s2,esp32s3"
RUSTC_MINIMAL_MINOR_VERSION="55"
INSTALLATION_MODE="install" # reinstall, uninstall
LLVM_VERSION="esp-14.0.0-20220415"
GCC_PATCH="esp-2021r2-patch3"
GCC_VERSION="8_4_0-esp-2021r2-patch3"
NIGHTLY_VERSION="nightly"
CLEAR_DOWNLOAD_CACHE="NO"
EXTRA_CRATES="ldproxy cargo-espflash"
ESP_IDF_VERSION=""
MINIFIED_ESP_IDF="NO"
IS_XTENSA_INSTALLED=0

display_help() {
  echo "Usage: install-rust-toolchain.sh <arguments>"
  echo "Arguments: "
  echo "-b|--build-target               Comma separated list of targets [esp32,esp32s2,esp32s3,esp32c3,all]. Defaults to: esp32,esp32s2,esp32s3"
  echo "-c|--cargo-home                 Cargo path"
  echo "-d|--toolchain-destination      Toolchain installation folder."
  echo "-e|--extra-crates               Extra crates to install. Defaults to: ldproxy cargo-espflash"
  echo "-f|--export-file                Destination of the export file generated."
  echo "-i|--installation-mode          Installation mode: [install, reinstall, uninstall]. Defaults to: install"
  echo "-l|--llvm-version               LLVM version"
  echo "-m|--minified-esp-idf           [Only applies if using -s|--esp-idf-version]. Deletes some esp-idf folder to save space. Possible values [YES, NO]"
  echo "-n|--nightly-version            Nightly Rust toolchain version"
  echo "-r|--rustup-home                Path to .rustup"
  echo "-s|--esp-idf-version            ESP-IDF version. When empty, no esp-idf is installed. Default: \"\""
  echo "-t|--toolchain-version          Xtensa Rust toolchain version"
  echo "-x|--clear-cache                Removes cached distribution files. Possible values [YES, NO]"
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
    -b|--build-target)
      BUILD_TARGET="$2"
      shift # past argument
      shift # past value
      ;;
    -d|--toolchain-destination)
      TOOLCHAIN_DESTINATION_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    -e|--extra-crates)
      EXTRA_CRATES="$2"
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
    -m|--minified-esp-idf)
      MINIFIED_ESP_IDF="$2"
      shift # past argument
      shift # past value
      ;;
    -n|--nightly-version)
      NIGHTLY_VERSION="$2"
      shift # past argument
      shift # past value
      ;;
    -r|--rustup-home)
      RUSTUP_HOME="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--esp-idf-version)
      ESP_IDF_VERSION="$2"
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
echo "--build-target          = ${BUILD_TARGET}"
echo "--cargo-home            = ${CARGO_HOME}"
echo "--clear-cache           = ${CLEAR_DOWNLOAD_CACHE}"
echo "--esp-idf-version       = ${ESP_IDF_VERSION}"
echo "--export-file           = ${EXPORT_FILE}"
echo "--extra-crates          = ${EXTRA_CRATES}"
echo "--installation-mode     = ${INSTALLATION_MODE}"
echo "--llvm-version          = ${LLVM_VERSION}"
echo "--minified-esp-idf      = ${MINIFIED_ESP_IDF}"
echo "--nightly-version       = ${NIGHTLY_VERSION}"
echo "--rustup-home           = ${RUSTUP_HOME}"
echo "--toolchain-version     = ${TOOLCHAIN_VERSION}"
echo "--toolchain-destination = ${TOOLCHAIN_DESTINATION_DIR}"

function install_rustup() {
    curl https://sh.rustup.rs -sSf | bash -s -- \
        --default-toolchain none --profile minimal -y
}

function install_rust() {
    curl https://sh.rustup.rs -sSf | bash -s -- --default-toolchain stable -y
}

function install_rust_toolchain() {
    rustup toolchain install $1
}

function source_cargo() {
    if [ -e "${HOME}/.cargo/env" ]; then
        source "${HOME}/.cargo/env"
        export CARGO_HOME="${HOME}/.cargo"
    else
        if [ -n "${CARGO_HOME}" ] && [ -e "${CARGO_HOME}/env" ]; then
            source ${CARGO_HOME}/env
        else
	    echo "Warning: Unable to source .cargo/env"
            export CARGO_HOME="${HOME}/.cargo"
        fi
    fi
}

function install_esp_idf() {
    if [ -z "${ESP_IDF_VERSION}" ]; then
        return
    fi

    mkdir -p ${IDF_TOOLS_PATH}/frameworks/
    NORMALIZED_VERSION=`echo ${ESP_IDF_VERSION} | sed -e 's!/!-!g'`
    export IDF_PATH="${IDF_TOOLS_PATH}/frameworks/esp-idf-${NORMALIZED_VERSION}"
    git clone --branch ${ESP_IDF_VERSION} --depth 1 --shallow-submodules \
        --recursive https://github.com/espressif/esp-idf.git \
        "${IDF_PATH}"
    ${IDF_PATH}/install.sh "${BUILD_TARGET}"
    python3 ${IDF_PATH}/tools/idf_tools.py install cmake
    if [ "${MINIFIED_ESP_IDF}" == "YES" ]; then
        rm -rf ${IDF_TOOLS_PATH}/dist
        rm -rf ${IDF_TOOLS_PATH}/frameworks/esp-idf/docs
        rm -rf ${IDF_TOOLS_PATH}/frameworks/esp-idf/examples
        rm -rf ${IDF_TOOLS_PATH}/frameworks/esp-idf/tools/esp_app_trace
        rm -rf ${IDF_TOOLS_PATH}/frameworks/esp-idf/tools/test_idf_size
    fi
}

function install_rust_xtensa_toolchain() {
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

    if [ "${ESP_IDF_VERSION}" == "" ]; then
        echo "* installing ${IDF_TOOL_XTENSA_ELF_GCC} "
        if [ ! -d ${IDF_TOOL_XTENSA_ELF_GCC} ]; then
            if [ ! -f "${GCC_FILE}" ]; then
                echo "** Downloading ${GCC_DIST_URL}"
                curl -LO "${GCC_DIST_URL}"
            fi
            mkdir -p "${IDF_TOOL_XTENSA_ELF_GCC}"
            echo "IDF_TOOL_XTENSA_ELF_GCC ${IDF_TOOL_XTENSA_ELF_GCC}"
            pwd
            tar xf ${GCC_FILE} -C "${IDF_TOOL_XTENSA_ELF_GCC}" --strip-components=1
            echo "done"
        else
            echo "already installed"
        fi
    fi
}

function install_llvm_clang() {
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

  echo " - ${GCC_FILE}"
  rm -f "${GCC_FILE}"
}

function install_rust_riscv_toolchain() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    --default-toolchain ${NIGHTLY_VERSION} \
    --component rust-src \
    --profile minimal \
    --target riscv32i-unknown-none-elf -y
}

function install_crate_from_zip() {
    CRATE_URL="$1"
    CRATE_BIN="$2"

    if [[ -z "${CRATE_BIN}" ]]; then
        return
    fi

    if [[ -z "${CRATE_URL}" ]]; then
        cargo install ${CRATE_BIN}
        return
    fi

    if [[ ! -e "${CRATE_BIN}" ]]; then
        echo "Downloading ${CRATE_URL} to ${CRATE_BIN}.zip"
        curl -L "${CRATE_URL}" -o "${CRATE_BIN}.zip"
        unzip "${CRATE_BIN}.zip" -d "${CARGO_HOME}/bin/"
        rm "${CRATE_BIN}.zip"
        chmod u+x "${CRATE_BIN}"
        echo "Using ${CRATE_BIN} binary release"
    fi
}

function install_crate_from_xz() {
    CRATE_URL="$1"
    CRATE_BIN="$2"

    if [[ -z "${CRATE_BIN}" ]]; then
        return
    fi

    if [[ -z "${CRATE_URL}" ]]; then
        cargo install ${CRATE_BIN}
        return
    fi

    if [[ ! -e "${CRATE_BIN}" ]]; then
        echo "Downloading ${CRATE_URL} to ${CRATE_BIN}.xz"
        curl -L "${CRATE_URL}" -o "${CRATE_BIN}.xz"
        unxz "${CRATE_BIN}.xz"
        chmod u+x "${CRATE_BIN}"
        echo "Using ${CRATE_BIN} binary release"
    fi
}

function install_extra_crates() {
    if [[ "${EXTRA_CRATES}" =~ "cargo-espflash" ]]; then
        install_crate_from_zip "${ESPFLASH_URL}" "${ESPFLASH_BIN}"
        EXTRA_CRATES="${EXTRA_CRATES/cargo-espflash/}"
    fi

    if [[ "${EXTRA_CRATES}" =~ "ldproxy" ]]; then
        install_crate_from_zip "${LDPROXY_URL}" "${LDPROXY_BIN}"
        EXTRA_CRATES="${EXTRA_CRATES/ldproxy/}"
    fi

    if [[ "${EXTRA_CRATES}" =~ "espmonitor" ]]; then
        install_crate_from_xz "${ESPMONITOR_URL}" "${ESPMONITOR_BIN}"
        EXTRA_CRATES="${EXTRA_CRATES/espmonitor/}"
    fi

    if ! [[ -z "${EXTRA_CRATES// }" ]];then
       cargo install $EXTRA_CRATES
    fi
}

# Check required tooling - rustc, rustfmt
command -v rustup || install_rustup

source_cargo

# Deploy missing toolchains - Xtensa toolchain should be used on top of these
rustup toolchain list | grep stable || install_rust_toolchain stable
rustup toolchain list | grep nightly || install_rust_toolchain nightly

# Check minimal rustc version
RUSTC_MINOR_VERSION=`rustc --version | sed -e 's/^rustc 1\.\([^.]*\).*/\1/'`
if [ "${RUSTC_MINOR_VERSION}" -lt "${RUSTC_MINIMAL_MINOR_VERSION}" ]; then
    echo "rustc version is too low, requires 1.${RUSTC_MINIMAL_MINOR_VERSION}"
    echo "calling rustup"
    install_rustup
fi

ARCH=`rustup show | grep "Default host" | sed -e 's/.* //'`

# Possible values of ARCH
#ARCH="aarch64-apple-darwin"
#ARCH="aarch64-unknown-linux-gnu"
#ARCH="x86_64-apple-darwin"
#ARCH="x86_64-unknown-linux-gnu"
#ARCH="x86_64-pc-windows-msvc"

#LLVM_DIST_MIRROR="https://github.com/espressif/llvm-project/releases/download/${LLVM_VERSION}"
LLVM_DIST_MIRROR="https://github.com/esp-rs/rust-build/releases/download/llvm-project-14.0-minified"
LLVM_ARCH="${ARCH}"

GCC_DIST_MIRROR="https://github.com/espressif/crosstool-NG/releases/download"

# Extra crates binary download support
ESPFLASH_URL=""
ESPFLASH_BIN=""
LDPROXY_URL=""
LDPROXY_BIN=""
ESPMONITOR_BIN=""
ESPMONITOR_URL=""

# Configuration overrides for specific architectures
if [ ${ARCH} == "aarch64-apple-darwin" ]; then
    GCC_ARCH="macos"
    ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash-${ARCH}.zip"
    ESPFLASH_BIN="${CARGO_HOME}/bin/cargo-espflash"
elif [ ${ARCH} == "x86_64-apple-darwin" ]; then
    #LLVM_ARCH="macos"
    GCC_ARCH="macos"
    ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash-${ARCH}.zip"
    ESPFLASH_BIN="${CARGO_HOME}/bin/cargo-espflash"
elif [ ${ARCH} == "x86_64-unknown-linux-gnu" ]; then
    GCC_ARCH="linux-amd64"
    ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash-${ARCH}.zip"
    ESPFLASH_BIN="${CARGO_HOME}/bin/cargo-espflash"
    LDPROXY_URL="https://github.com/esp-rs/embuild/releases/latest/download/ldproxy-${ARCH}.zip"
    LDPROXY_BIN="${CARGO_HOME}/bin/ldproxy"
    ESPMONITOR_URL="https://github.com/esp-rs/rust-build/releases/download/v1.60.0.1/espmonitor-0.7.0-${ARCH}.xz"
    ESPMONITOR_BIN="${CARGO_HOME}/bin/espmonitor"
elif [ ${ARCH} == "aarch64-unknown-linux-gnu" ]; then
    GCC_ARCH="linux-arm64"
elif [ ${ARCH} == "x86_64-pc-windows-msvc" ]; then
    #LLVM_ARCH="win64"
    GCC_ARCH="win64"
    ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash-${ARCH}.zip"
    ESPFLASH_BIN="${CARGO_HOME}/bin/cargo-espflash.exe"
fi

echo "Processing toolchain for ${ARCH} - operation: ${INSTALLATION_MODE}"


RUST_DIST="rust-${TOOLCHAIN_VERSION}-${ARCH}"
RUST_SRC_DIST="rust-src-${TOOLCHAIN_VERSION}"
LLVM_ARTIFACT_VERSION=`echo ${LLVM_VERSION} | sed -e 's/.*esp-//g' -e 's/-.*//g' -e 's/\./_/g'`
LLVM_FILE="xtensa-esp32-elf-llvm${LLVM_ARTIFACT_VERSION}-${LLVM_VERSION}-${LLVM_ARCH}.tar.xz"
LLVM_DIST_URL="${LLVM_DIST_MIRROR}/${LLVM_FILE}"


GCC_FILE="xtensa-esp32-elf-gcc${GCC_VERSION}-${GCC_ARCH}.tar.gz"
GCC_DIST_URL="${GCC_DIST_MIRROR}/${GCC_PATCH}/${GCC_FILE}"

if [ -z "${IDF_TOOLS_PATH}" ]; then
    IDF_TOOLS_PATH="${HOME}/.espressif"
fi

IDF_TOOL_XTENSA_ELF_CLANG="${IDF_TOOLS_PATH}/tools/xtensa-esp32-elf-clang/${LLVM_VERSION}-${ARCH}"
IDF_TOOL_XTENSA_ELF_GCC="${IDF_TOOLS_PATH}/tools/xtensa-esp32-elf-gcc/${GCC_VERSION}-${ARCH}"

RUST_DIST_URL="https://github.com/esp-rs/rust-build/releases/download/v${TOOLCHAIN_VERSION}/${RUST_DIST}.tar.xz"

if [ "${INSTALLATION_MODE}" == "uninstall" ] || [ "${INSTALLATION_MODE}" == "reinstall" ] ; then
    echo "Removing:"

    echo " - ${TOOLCHAIN_DESTINATION_DIR}"
    rm -rf "${TOOLCHAIN_DESTINATION_DIR}"

    echo " - ${IDF_TOOL_XTENSA_ELF_CLANG}"
    rm -rf "${IDF_TOOL_XTENSA_ELF_CLANG}"

    echo " - ${IDF_TOOL_XTENSA_ELF_GCC}"
    rm -rf "${IDF_TOOL_XTENSA_ELF_GCC}"

    if [ "${CLEAR_DOWNLOAD_CACHE}" == "YES" ]; then
        clear_download_cache
    fi

    if [ "${INSTALLATION_MODE}" == "uninstall" ]; then
        exit 0
    fi
fi

if [[ "${BUILD_TARGET}" =~ esp32c3 ]]; then
    install_rust_riscv_toolchain
fi

if [[ "${BUILD_TARGET}" =~ esp32s[2|3] || "${BUILD_TARGET}" =~ esp32[,|\ ] || "${BUILD_TARGET}" =~ esp32$ ]]; then
    install_rust_xtensa_toolchain
    IS_XTENSA_INSTALLED=1
fi

install_llvm_clang
install_esp_idf
install_extra_crates

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
if [ ${IS_XTENSA_INSTALLED} -eq 1 ]; then
    if [ "${ESP_IDF_VERSION}" == "" ]; then
        echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:${IDF_TOOL_XTENSA_ELF_GCC}/bin/:\$PATH\"
    else
        echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:\$PATH\"
    fi
    echo export LIBCLANG_PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/lib/\"
    # Workaround of https://github.com/espressif/esp-idf/issues/7910
    echo 'export PIP_USER="no"'
fi

if [ "${ESP_IDF_VERSION}" != "" ]; then
    echo "export IDF_TOOLS_PATH=${IDF_TOOLS_PATH}"
    echo "source ${IDF_PATH}/export.sh"
fi

# Store export instructions in the file
if [[ ! -z "${EXPORT_FILE}" ]]; then
    if [ ${IS_XTENSA_INSTALLED} -eq 1 ]; then
        if [ "${ESP_IDF_VERSION}" == "" ]; then
            echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:${IDF_TOOL_XTENSA_ELF_GCC}/bin/:\$PATH\" > "${EXPORT_FILE}"
        else
            echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:\$PATH\" > "${EXPORT_FILE}"
        fi
        echo export LIBCLANG_PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/lib/\" >> "${EXPORT_FILE}"
        echo 'export PIP_USER="no"' >> "${EXPORT_FILE}"
    fi
    if [ "${ESP_IDF_VERSION}" != "" ]; then
        echo "export IDF_TOOLS_PATH=${IDF_TOOLS_PATH}" >> "${EXPORT_FILE}"
        echo "source ${IDF_PATH}/export.sh /dev/null 2>&1" >> "${EXPORT_FILE}"
    fi
fi
