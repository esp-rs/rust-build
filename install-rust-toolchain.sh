#!/usr/bin/env bash

# Default values
TOOLCHAIN_VERSION="1.60.0.1"
if [ -z "${RUSTUP_HOME}" ]; then
    RUSTUP_HOME="${HOME}/.rustup"
fi
TOOLCHAIN_DESTINATION_DIR="${RUSTUP_HOME}/toolchains/esp"
BUILD_TARGET="esp32,esp32s2,esp32s3"
ESP_BOARDS=""
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

display_help() {
  echo "Usage: install-rust-toolchain.sh <arguments>"
  echo "Arguments: "
  echo "-b|--build-target               Comma separated list of targets [esp32,esp32s2,esp32s3,esp32c3,all]. Defaults to: esp32,esp32s2,esp32s3"
  echo "-c|--cargo-home                 Cargo path"
  echo "-d|--toolchain-destination      Toolchain instalation folder."
  echo "-e|--extra-crates               Extra crates to install. Defaults to: ldproxy cargo-espflash"
  echo "-f|--export-file                Destination of the export file generated."
  echo "-i|--installation-mode          Installation mode: [install, reinstall, uninstall]. Defaults to: install"
  echo "-l|--llvm-version               LLVM version"
  echo "-m|--minified-esp-idf           [Only applies if using -s|--esp-idf-version]. Deletes some esp-idf folder to save space. Possible values [YES, NO]"
  echo "-n|--nightly-version            Nightly Rust toolchain version"
  echo "-r|--rustup-home                Path to .rustup"
  echo "-s|--esp-idf-version            ESP-IDF version.When empty, no esp-idf is installed. Default: \"\""
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
      IFS=',' read -r -a ESP_BOARDS <<< "$BUILD_TARGET"
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

function install_extra_crates() {
    if [[ ! -z "${EXTRA_CRATES}" ]]; then
        for CRATE in ${EXTRA_CRATES}; do
            echo "Installing additional extra crate: ${CRATE}"
            if [ "${CRATE}" = "cargo-espflash" ] && [[ ! -z "${ESPFLASH_URL}" ]]; then
                if [[ ! -e "${ESPFLASH_BIN}" ]]; then
                    curl -L "${ESPFLASH_URL}" -o "${ESPFLASH_BIN}.zip"
                    unzip "${ESPFLASH_BIN}.zip" -d "${CARGO_HOME}/bin/"
                    rm "${ESPFLASH_BIN}.zip"
                    chmod u+x "${ESPFLASH_BIN}"
                fi
                echo "Using cargo-espflash binary release"
            elif [ "${CRATE}" = "ldproxy" ] && [[ ! -z "${LDPROXY_URL}" ]]; then
                if [[ ! -e "${LDPROXY_BIN}" ]]; then
                    curl -L "${LDPROXY_URL}" -o "${LDPROXY_BIN}.xz"
                    unxz "${LDPROXY_BIN}.xz"
                    chmod u+x "${LDPROXY_BIN}"
                fi
                echo "Using ldproxy binary release"
            elif [ "${CRATE}" = "espmonitor" ] && [[ ! -z "${ESPMONITOR_URL}" ]]; then
                if [[ ! -e "${ESPMONITOR_BIN}" ]]; then
                    curl -L "${ESPMONITOR_URL}" -o "${ESPMONITOR_BIN}.xz"
                    unxz "${ESPMONITOR_BIN}.xz"
                    chmod u+x "${ESPMONITOR_BIN}"
                fi
                echo "Using espmonitor binary release"
            else
                cargo install ${CRATE}
            fi
        done
    fi
}
set -e
#set -v

# Check required tooling - rustc, rustfmt
command -v rustup || install_rustup

source_cargo

# Check minimal rustc version
RUSTC_MINOR_VERSION=`rustc --version | sed -e 's/^rustc 1\.\([^.]*\).*/\1/'`
if [ "${RUSTC_MINOR_VERSION}" -lt "${RUSTC_MINIMAL_MINOR_VERSION}" ]; then
    echo "rustc version is too low, requires 1.${RUSTC_MINIMAL_MINOR_VERSION}"
    echo "calling rustup"
    install_rustup
fi

ARCH=`rustup show | grep "Default host" | sed -e 's/.* //'`
LLVM_DIST_MIRROR="https://github.com/espressif/llvm-project/releases/download/${LLVM_VERSION}"
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
    LLVM_ARCH="${ARCH}"
    GCC_ARCH="macos"
    # LLVM artifact is stored as part of Rust release
    LLVM_DIST_MIRROR="https://github.com/esp-rs/rust-build/releases/download/v${TOOLCHAIN_VERSION}"
    ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash-${ARCH}.zip"
    ESPFLASH_BIN="${CARGO_HOME}/bin/cargo-espflash"
elif [ ${ARCH} == "x86_64-apple-darwin" ]; then
    LLVM_ARCH="macos"
    GCC_ARCH="macos"
    ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash-${ARCH}.zip"
    ESPFLASH_BIN="${CARGO_HOME}/bin/cargo-espflash"
elif [ ${ARCH} == "x86_64-unknown-linux-gnu" ]; then
    LLVM_ARCH="${ARCH}"
    GCC_ARCH="linux-amd64"
    ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash-${ARCH}.zip"
    ESPFLASH_BIN="${CARGO_HOME}/bin/cargo-espflash"
    LDPROXY_URL="https://github.com/esp-rs/rust-build/releases/download/v1.60.0.1/ldproxy-0.3.0-x86_64-unknown-linux-gnu.xz"
    LDPROXY_BIN="${CARGO_HOME}/bin/ldproxy"
    ESPMONITOR_URL="https://github.com/esp-rs/rust-build/releases/download/v1.60.0.1/espmonitor-0.7.0-x86_64-unknown-linux-gnu.xz"
    ESPMONITOR_BIN="${CARGO_HOME}/bin/espmonitor"
    LLVM_DIST_MIRROR="https://github.com/esp-rs/rust-build/releases/download/v${TOOLCHAIN_VERSION}"
elif [ ${ARCH} == "aarch64-unknown-linux-gnu" ]; then
    LLVM_ARCH="${ARCH}"
    GCC_ARCH="linux-arm64"
    # LLVM artifact is stored as part of Rust release
    LLVM_DIST_MIRROR="https://github.com/esp-rs/rust-build/releases/download/v${TOOLCHAIN_VERSION}"
elif [ ${ARCH} == "x86_64-pc-windows-msvc" ]; then
    LLVM_ARCH="win64"
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

echo "GCC_FILE ${GCC_FILE}"
echo "GCC_DIST_URL ${GCC_DIST_URL}"


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

XTENSA_INSTALLED=false
RISCV_INSTALLED=false
for BOARD in "${ESP_BOARDS[@]}"; do
    if [ "${BOARD}" == "esp32c3" ] && [ ${RISCV_INSTALLED} == "false" ]; then
        install_rust_riscv_toolchain
        RISCV_INSTALLED=true
    elif ([ "${BOARD}" == "esp32" ] || [ "${BOARD}" == "esp32s3" ] || [ "${BOARD}" == "esp32s2" ]) && ([ ${XTENSA_INSTALLED} == "false" ]); then
        install_rust_xtensa_toolchain
        XTENSA_INSTALLED=true
    elif [ "${BOARD}" == "all" ]; then
        install_rust_riscv_toolchain
        RISCV_INSTALLED=true
        install_rust_xtensa_toolchain
        XTENSA_INSTALLED=true
    elif [ "${BOARD}" != "esp32" ] && [ "${BOARD}" != "esp32s3" ] && [ "${BOARD}" != "esp32s2" ] && [ "${BOARD}" != "esp32c3" ] && [ "${BOARD}" != "all" ]; then
        echo "Incorrect build target: ${BOARD}"
        exit 0
    fi
done


if [ ${XTENSA_INSTALLED} == "true" ]; then
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

fi

install_extra_crates

if [ ${XTENSA_INSTALLED} == "true" ]; then
    if [ "${CLEAR_DOWNLOAD_CACHE}" == "YES" ]; then
        clear_download_cache
    fi
fi

if [ "${ESP_IDF_VERSION}" != "" ]; then
    mkdir -p ${IDF_TOOLS_PATH}/frameworks/
    git clone --branch ${ESP_IDF_VERSION} --depth 1 --shallow-submodules \
        --recursive https://github.com/espressif/esp-idf.git \
        ${IDF_TOOLS_PATH}/frameworks/esp-idf
    python3 ${IDF_TOOLS_PATH}/frameworks/esp-idf/tools/idf_tools.py install cmake
    for BOARD in "${ESP_BOARDS[@]}"; do
        ${IDF_TOOLS_PATH}/frameworks/esp-idf/install.sh ${BOARD}
    done
    if [ "${MINIFIED_ESP_IDF}" == "YES" ]; then
        rm -rf ${IDF_TOOLS_PATH}/dist
        rm -rf ${IDF_TOOLS_PATH}/frameworks/esp-idf/docs
        rm -rf ${IDF_TOOLS_PATH}/frameworks/esp-idf/examples
        rm -rf ${IDF_TOOLS_PATH}/frameworks/esp-idf/tools/esp_app_trace
        rm -rf ${IDF_TOOLS_PATH}/frameworks/esp-idf/tools/test_idf_size
    fi
fi

PROFILE_NAME="your default shell"
if grep -q "zsh" <<< "$SHELL"; then
  PROFILE_NAME=~/.zshrc
elif grep -q "bash" <<< "$SHELL"; then
  PROFILE_NAME=~/.bashrc
fi

echo "Add following command to $PROFILE_NAME"
if [ ${XTENSA_INSTALLED} == "true" ]; then
    if [ "${ESP_IDF_VERSION}" == "" ]; then
        echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:${IDF_TOOL_XTENSA_ELF_GCC}/bin/:\$PATH\"
    else
        echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:\$PATH\"
    fi
    echo export LIBCLANG_PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/lib/\"
    # Workaround of https://github.com/espressif/esp-idf/issues/7910
    echo export PIP_USER="no"
fi
if [ "${ESP_IDF_VERSION}" != "" ]; then
    echo export IDF_TOOLS_PATH=${IDF_TOOLS_PATH}
    echo source ${IDF_TOOLS_PATH}/frameworks/esp-idf/export.sh
fi
# Store export instructions in the file
if [[ ! -z "${EXPORT_FILE}" ]]; then
    if [ ${XTENSA_INSTALLED} == "true" ]; then
        if [ "${ESP_IDF_VERSION}" == "" ]; then
            echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:${IDF_TOOL_XTENSA_ELF_GCC}/bin/:\$PATH\" > "${EXPORT_FILE}"
        else
            echo export PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/bin/:\$PATH\" > "${EXPORT_FILE}"
        fi
        echo export LIBCLANG_PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/lib/\" >> "${EXPORT_FILE}"
        echo export PIP_USER="no" >> "${EXPORT_FILE}"
    fi
    if [ "${ESP_IDF_VERSION}" != "" ]; then
        echo export IDF_TOOLS_PATH=${IDF_TOOLS_PATH} >> "${EXPORT_FILE}"
        echo "source ${IDF_TOOLS_PATH}/frameworks/esp-idf/export.sh /dev/null 2>&1" >> "${EXPORT_FILE}"
    fi
fi