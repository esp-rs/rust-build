#!/usr/bin/env bash

set -eu
#set -v

# Default values
TOOLCHAIN_VERSION="1.65.0.1"
RUSTUP_HOME="${RUSTUP_HOME:-${HOME}/.rustup}"
CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}"
TOOLCHAIN_DESTINATION_DIR="${RUSTUP_HOME}/toolchains/esp"
BUILD_TARGET="esp32,esp32s2,esp32s3"
RUSTC_MINIMAL_MINOR_VERSION="55"
INSTALLATION_MODE="install" # reinstall, uninstall
LLVM_VERSION="esp-15.0.0-20221014"
LLVM_DIST_MIRROR="https://github.com/espressif/llvm-project/releases/download/${LLVM_VERSION}"
MINIFIED_LLVM="YES"
GCC_DIST_MIRROR="https://github.com/espressif/crosstool-NG/releases/download"
GCC_PATCH="esp-2021r2-patch3"
GCC_VERSION="8_4_0-esp-2021r2-patch3"
NIGHTLY_VERSION="nightly"
CLEAR_DOWNLOAD_CACHE="YES"
EXTRA_CRATES="ldproxy cargo-espflash"
ESP_IDF_VERSION=""
MINIFIED_ESP_IDF="NO"
IS_XTENSA_INSTALLED=0
IS_SCCACHE_INSTALLED=0
EXPORT_FILE="export-esp.sh"

display_help() {
    echo "Usage: install-rust-toolchain.sh <arguments>"
    echo "Arguments: "
    echo "-b|--build-target               Comma separated list of targets [esp32,esp32s2,esp32s3,esp32c3,all]. Defaults to: esp32,esp32s2,esp32s3"
    echo "-c|--cargo-home                 Cargo path"
    echo "-d|--toolchain-destination      Toolchain installation folder."
    echo "-e|--extra-crates               Extra crates to install. Defaults to: ldproxy cargo-espflash"
    echo "-f|--export-file                Destination of the export file generated. Defaults to: export-esp.sh"
    echo "-i|--installation-mode          Installation mode: [install, reinstall, uninstall]. Defaults to: install"
    echo "-k|--minified-llvm              Use minified LLVM. Possible values [YES, NO]"
    echo "-l|--llvm-version               LLVM version"
    echo "-m|--minified-esp-idf           [Only applies if using -s|--esp-idf-version]. Deletes some esp-idf folder to save space. Possible values [YES, NO]"
    echo "-n|--nightly-version            Nightly Rust toolchain version"
    echo "-r|--rustup-home                Path to .rustup"
    echo "-s|--esp-idf-version            ESP-IDF version. When empty, no esp-idf is installed. Default: \"\""
    echo "-t|--toolchain-version          Xtensa Rust toolchain version"
    echo "-x|--clear-cache                Removes cached distribution files. Possible values [YES, NO]"
}

# Process arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -h | --help)
        display_help
        exit 1
        ;;
    -b | --build-target)
        BUILD_TARGET="$2"
        shift # past argument
        shift # past value
        ;;
    -d | --toolchain-destination)
        TOOLCHAIN_DESTINATION_DIR="$2"
        shift # past argument
        shift # past value
        ;;
    -e | --extra-crates)
        EXTRA_CRATES="$2"
        shift # past argument
        shift # past value
        ;;
    -f | --export-file)
        EXPORT_FILE="$2"
        shift # past argument
        shift # past value
        ;;
    -o | --cargo-home)
        CARGO_HOME="$2"
        shift # past argument
        shift # past value
        ;;
    -i | --installation-mode)
        INSTALLATION_MODE="$2"
        shift # past argument
        shift # past value
        ;;
    -k | --minified-llvm)
        MINIFIED_LLVM="$2"
        shift # past argument
        shift # past value
        ;;
    -l | --llvm-version)
        LLVM_VERSION="$2"
        LLVM_DIST_MIRROR="https://github.com/espressif/llvm-project/releases/download/${LLVM_VERSION}"
        shift # past argument
        shift # past value
        ;;
    -m | --minified-esp-idf)
        MINIFIED_ESP_IDF="$2"
        shift # past argument
        shift # past value
        ;;
    -n | --nightly-version)
        NIGHTLY_VERSION="$2"
        shift # past argument
        shift # past value
        ;;
    -r | --rustup-home)
        RUSTUP_HOME="$2"
        shift # past argument
        shift # past value
        ;;
    -s | --esp-idf-version)
        ESP_IDF_VERSION="$2"
        shift # past argument
        shift # past value
        ;;
    -t | --toolchain-version)
        TOOLCHAIN_VERSION="$2"
        shift # past argument
        shift # past value
        ;;
    -x | --clear-cache)
        CLEAR_DOWNLOAD_CACHE="$2"
        shift # past argument
        shift # past value
        ;;
    *) # unknown option
        echo "Warning: Unknown argument."
        shift # past argument
        ;;
    esac
done

echo "Processing configuration:"
echo "--build-target          = ${BUILD_TARGET}"
echo "--cargo-home            = ${CARGO_HOME}"
echo "--clear-cache           = ${CLEAR_DOWNLOAD_CACHE}"
echo "--esp-idf-version       = ${ESP_IDF_VERSION}"
echo "--export-file           = ${EXPORT_FILE:-}"
echo "--extra-crates          = ${EXTRA_CRATES}"
echo "--installation-mode     = ${INSTALLATION_MODE}"
echo "--llvm-version          = ${LLVM_VERSION}"
echo "--minified-esp-idf      = ${MINIFIED_ESP_IDF}"
echo "--minified-llvm         = ${MINIFIED_LLVM}"
echo "--nightly-version       = ${NIGHTLY_VERSION}"
echo "--rustup-home           = ${RUSTUP_HOME}"
echo "--toolchain-version     = ${TOOLCHAIN_VERSION}"
echo "--toolchain-destination = ${TOOLCHAIN_DESTINATION_DIR}"

function install_rustup() {
    curl https://sh.rustup.rs -sSf | bash -s -- \
        --default-toolchain none --profile minimal -y
}

function install_rust_toolchain() {
    rustup toolchain install $1 --profile minimal
}

function source_cargo() {
    if [[ -e "${HOME}/.cargo/env" ]]; then
        source "${HOME}/.cargo/env"
        export CARGO_HOME="${HOME}/.cargo"
    else
        if [[ -n "${CARGO_HOME}" ]] && [[ -e "${CARGO_HOME}/env" ]]; then
            source ${CARGO_HOME}/env
        else
            echo "Warning: Unable to source .cargo/env"
            export CARGO_HOME="${HOME}/.cargo"
        fi
    fi
}

function install_esp_idf() {
    mkdir -p ${IDF_TOOLS_PATH}/frameworks/
    NORMALIZED_VERSION=$(echo ${ESP_IDF_VERSION} | sed -e 's!/!-!g')
    export IDF_PATH="${IDF_TOOLS_PATH}/frameworks/esp-idf-${NORMALIZED_VERSION}"
    git clone --branch ${ESP_IDF_VERSION} --depth 1 --shallow-submodules \
        --recursive https://github.com/espressif/esp-idf.git \
        "${IDF_PATH}"
    ${IDF_PATH}/install.sh "${BUILD_TARGET}"
    python3 ${IDF_PATH}/tools/idf_tools.py install cmake
    if [[ "${MINIFIED_ESP_IDF}" == "YES" ]]; then
        rm -rf ${IDF_TOOLS_PATH}/dist
        rm -rf ${IDF_TOOLS_PATH}/frameworks/esp-idf/docs
        rm -rf ${IDF_TOOLS_PATH}/frameworks/esp-idf/examples
        rm -rf ${IDF_TOOLS_PATH}/frameworks/esp-idf/tools/esp_app_trace
        rm -rf ${IDF_TOOLS_PATH}/frameworks/esp-idf/tools/test_idf_size
    fi
}

function install_gcc() {
    IDF_TOOL_GCC="${IDF_TOOLS_PATH}/tools/$1-gcc/${GCC_VERSION}-${ARCH}"
    GCC_FILE="$1-gcc${GCC_VERSION}-${GCC_ARCH}.tar.gz"
    GCC_DIST_URL="${GCC_DIST_MIRROR}/${GCC_PATCH}/${GCC_FILE}"
    echo "* installing ${IDF_TOOL_GCC} "
    if [[ ! -d ${IDF_TOOL_GCC} ]]; then
        if [[ ! -f "${GCC_FILE}" ]]; then
            echo "** Downloading ${GCC_DIST_URL}"
            curl -LO "${GCC_DIST_URL}"
        fi
        mkdir -p "${IDF_TOOL_GCC}"
        echo "IDF_TOOL_GCC ${IDF_TOOL_GCC}"
        tar xf ${GCC_FILE} -C "${IDF_TOOL_GCC}" --strip-components=1
        echo "done"
    else
        echo "already installed"
    fi
    IDF_TOOL_GCC_PATH="${IDF_TOOL_GCC}/bin/${IDF_TOOL_GCC_PATH:+:${IDF_TOOL_GCC_PATH}}"
}

function install_rust_xtensa_toolchain() {
    if [[ -d "${TOOLCHAIN_DESTINATION_DIR}" ]]; then
        echo "Previous installation of toolchain exist in: ${TOOLCHAIN_DESTINATION_DIR}"
        echo "Please, remove the directory before new installation."
        exit 1
    fi

    if [[ ! -d ${TOOLCHAIN_DESTINATION_DIR} ]]; then
        mkdir -p ${TOOLCHAIN_DESTINATION_DIR}
        if [[ ! -f ${RUST_DIST}.tar.xz ]]; then
            echo "** downloading: ${RUST_DIST_URL}"
            curl -LO "${RUST_DIST_URL}"
            mkdir -p ${RUST_DIST}
            tar xf ${RUST_DIST}.tar.xz --strip-components=1 -C ${RUST_DIST}
        fi
        ./${RUST_DIST}/install.sh --destdir=${TOOLCHAIN_DESTINATION_DIR} --prefix="" --without=rust-docs

        if [[ ! -f ${RUST_SRC_DIST}.tar.xz ]]; then
            curl -LO "https://github.com/esp-rs/rust-build/releases/download/v${TOOLCHAIN_VERSION}/${RUST_SRC_DIST}.tar.xz"
            mkdir -p ${RUST_SRC_DIST}
            tar xf ${RUST_SRC_DIST}.tar.xz --strip-components=1 -C ${RUST_SRC_DIST}
        fi
        ./${RUST_SRC_DIST}/install.sh --destdir=${TOOLCHAIN_DESTINATION_DIR} --prefix="" --without=rust-docs
    fi

    if [[ -z "${ESP_IDF_VERSION}" ]]; then
        if [[ "${BUILD_TARGET}" =~ "esp32s3" ]]; then
            install_gcc "xtensa-esp32s3-elf"
        fi
        if [[ "${BUILD_TARGET}" =~ "esp32s2" ]]; then
            install_gcc "xtensa-esp32s2-elf"
        fi
        if [[ "${BUILD_TARGET}" =~ esp32[,|\ ] || "${BUILD_TARGET}" =~ esp32$ ]]; then
            install_gcc "xtensa-esp32-elf"
        fi
    fi
}

function install_llvm_clang() {
    echo "* installing ${IDF_TOOL_XTENSA_ELF_CLANG} "
    if [[ ! -d ${IDF_TOOL_XTENSA_ELF_CLANG} ]]; then
        if [[ ! -f "${LLVM_FILE}" ]]; then
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

    if [[ -z "${ESP_IDF_VERSION}" ]]; then
        echo " - *-elf-gcc*.tar.gz"
        rm -f *-elf-gcc*.tar.gz
    fi
}

function install_rust_riscv_toolchain() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
        --default-toolchain ${NIGHTLY_VERSION} \
        --component rust-src \
        --profile minimal \
        --target riscv32imc-unknown-none-elf -y
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

function install_crate_from_tar_gz() {
    CRATE_URL="$1"
    CRATE_BIN="$2"
    STRIP_COMPONENTS="$3"

    if [[ -z "${CRATE_BIN}" ]]; then
        return
    fi

    if [[ -z "${CRATE_URL}" ]]; then
        cargo install ${CRATE_BIN}
        return
    fi

    if [[ ! -e "${CRATE_BIN}" ]]; then
        echo "Downloading ${CRATE_URL} to ${CRATE_BIN}.tar.gz"
        curl -L "${CRATE_URL}" -o "${CRATE_BIN}.tar.gz"
        if [[ -z "${STRIP_COMPONENTS}" ]]; then
            tar xf "${CRATE_BIN}.tar.gz" -C ${CARGO_HOME}/bin
        else
            tar xf "${CRATE_BIN}.tar.gz" -C ${CARGO_HOME}/bin --strip-components 1
        fi
        chmod u+x "${CRATE_BIN}"
        echo "Using ${CRATE_BIN} binary release"
    fi
}

function install_extra_crates() {
    if [[ "${EXTRA_CRATES}" =~ "cargo-espflash" ]] && [[ -n "${CARGO_ESPFLASH_URL}" ]] && [[ -n "${CARGO_ESPFLASH_BIN}" ]]; then
        install_crate_from_zip "${CARGO_ESPFLASH_URL}" "${CARGO_ESPFLASH_BIN}"
        EXTRA_CRATES="${EXTRA_CRATES/cargo-espflash/}"
    fi

    if [[ "${EXTRA_CRATES}" =~ "espflash" ]] && [[ -n "${ESPFLASH_URL}" ]] && [[ -n "${ESPFLASH_BIN}" ]]; then
        install_crate_from_zip "${ESPFLASH_URL}" "${ESPFLASH_BIN}"
        EXTRA_CRATES="${EXTRA_CRATES/espflash/}"
    fi

    if [[ "${EXTRA_CRATES}" =~ "ldproxy" ]] && [[ -n "${LDPROXY_URL}" ]] && [[ -n "${LDPROXY_BIN}" ]]; then
        install_crate_from_zip "${LDPROXY_URL}" "${LDPROXY_BIN}"
        EXTRA_CRATES="${EXTRA_CRATES/ldproxy/}"
    fi

    if [[ "${EXTRA_CRATES}" =~ "cargo-generate" ]] && [[ -n "${GENERATE_URL}" ]] && [[ -n "${GENERATE_BIN}" ]]; then
        install_crate_from_tar_gz "${GENERATE_URL}" "${GENERATE_BIN}" ""
        EXTRA_CRATES="${EXTRA_CRATES/cargo-generate/}"
    fi

    if [[ "${EXTRA_CRATES}" =~ "sccache" ]]; then
        IS_SCCACHE_INSTALLED=1
        if [[ -n "${SCCACHE_URL}" ]] && [[ -n "${SCCACHE_BIN}" ]]; then
            install_crate_from_tar_gz "${SCCACHE_URL}" "${SCCACHE_BIN}" "STRIP"
            EXTRA_CRATES="${EXTRA_CRATES/sccache/}"
        fi
    fi

    if [[ "${EXTRA_CRATES}" =~ "web-flash" ]]; then
        if [[ -n "${WEB_FLASH_URL}" ]] && [[ -n "${WEB_FLASH_BIN}" ]]; then
            install_crate_from_zip "${WEB_FLASH_URL}" "${WEB_FLASH_BIN}"
        else
            cargo install web-flash --git https://github.com/bjoernQ/esp-web-flash-server
        fi
        EXTRA_CRATES="${EXTRA_CRATES/web-flash/}"
    fi

    if [[ "${EXTRA_CRATES}" =~ "wokwi-server" ]]; then
        if [[ -n "${WOKWI_SERVER_URL}" ]] && [[ -n "${WOKWI_SERVER_BIN}" ]]; then
            install_crate_from_zip "${WOKWI_SERVER_URL}" "${WOKWI_SERVER_BIN}"
        else
            RUSTFLAGS="--cfg tokio_unstable" cargo install wokwi-server --git https://github.com/MabezDev/wokwi-server --locked
        fi
        EXTRA_CRATES="${EXTRA_CRATES/wokwi-server/}"
    fi

    if ! [[ -z "${EXTRA_CRATES// /}" ]]; then
        cargo install $EXTRA_CRATES
    fi
}

# Check required tooling - rustc, rustfmt
command -v rustup || install_rustup

source_cargo

if [[ "${BUILD_TARGET}" == all ]]; then
    BUILD_TARGET="esp32,esp32s2,esp32s3,esp32c3"
fi

# Deploy missing toolchains - Xtensa toolchain should be used on top of these
if [[ "${BUILD_TARGET}" =~ esp32s[2|3] || "${BUILD_TARGET}" =~ esp32[,|\ ] || "${BUILD_TARGET}" =~ esp32$ ]]; then
    rustup toolchain list | grep ${NIGHTLY_VERSION} || install_rust_toolchain ${NIGHTLY_VERSION}
fi

if [[ "${BUILD_TARGET}" =~ esp32c3 ]]; then
    install_rust_riscv_toolchain
fi

# Check minimal rustc version
RUSTC_MINOR_VERSION=$(rustc --version | sed -e 's/^rustc 1\.\([^.]*\).*/\1/')
if [[ "${RUSTC_MINOR_VERSION}" -lt "${RUSTC_MINIMAL_MINOR_VERSION}" ]]; then
    echo "rustc version is too low, requires 1.${RUSTC_MINIMAL_MINOR_VERSION}"
    echo "calling rustup"
    install_rustup
fi

ARCH=$(rustup show | grep "Default host" | sed -e 's/.* //')
# Possible values of ARCH
#ARCH="aarch64-apple-darwin"
#ARCH="aarch64-unknown-linux-gnu"
#ARCH="x86_64-apple-darwin"
#ARCH="x86_64-unknown-linux-gnu"
#ARCH="x86_64-pc-windows-msvc"

# Extra crates binary download support
ESPFLASH_URL=""
ESPFLASH_BIN=""
CARGO_ESPFLASH_URL=""
CARGO_ESPFLASH_BIN=""
LDPROXY_URL=""
LDPROXY_BIN=""
GENERATE_URL=""
GENERATE_BIN=""
SCCACHE_URL=""
SCCACHE_BIN=""
WOKWI_SERVER_URL=""
WOKWI_SERVER_BIN=""
WEB_FLASH_URL=""
WEB_FLASH_BIN=""
if [[ "${EXTRA_CRATES}" =~ "cargo-generate" ]]; then
    GENERATE_VERSION=$(git ls-remote --refs --sort="version:refname" --tags "https://github.com/cargo-generate/cargo-generate" | cut -d/ -f3- | tail -n1)
fi
if [[ "${EXTRA_CRATES}" =~ "sccache" ]]; then
    SCCACHE_VERSION=$(git ls-remote --refs --sort="version:refname" --tags "https://github.com/mozilla/sccache" | cut -d/ -f3- | tail -n1)
fi

# Configuration overrides for specific architectures
if [[ ${ARCH} == "aarch64-apple-darwin" ]]; then
    GCC_ARCH="macos"
    LLVM_ARCH="macos-arm64"
    CARGO_ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash-${ARCH}.zip"
    CARGO_ESPFLASH_BIN="${CARGO_HOME}/bin/cargo-espflash"
    ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/espflash-${ARCH}.zip"
    ESPFLASH_BIN="${CARGO_HOME}/bin/espflash"
    LDPROXY_URL="https://github.com/esp-rs/embuild/releases/latest/download/ldproxy-${ARCH}.zip"
    LDPROXY_BIN="${CARGO_HOME}/bin/ldproxy"
    if [[ "${EXTRA_CRATES}" =~ "sccache" ]]; then
        SCCACHE_URL="https://github.com/mozilla/sccache/releases/latest/download/sccache-${SCCACHE_VERSION}-${ARCH}.tar.gz"
    fi
    SCCACHE_BIN="${CARGO_HOME}/bin/sccache"
    WOKWI_SERVER_URL="https://github.com/MabezDev/wokwi-server/releases/latest/download/wokwi-server-${ARCH}.zip"
    WOKWI_SERVER_BIN="${CARGO_HOME}/bin/wokwi-server"
    WEB_FLASH_URL="https://github.com/bjoernQ/esp-web-flash-server/releases/latest/download/web-flash-${ARCH}.zip"
    WEB_FLASH_BIN="${CARGO_HOME}/bin/web-flash"
elif [[ ${ARCH} == "x86_64-apple-darwin" ]]; then
    GCC_ARCH="macos"
    LLVM_ARCH="macos"
    CARGO_ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash-${ARCH}.zip"
    CARGO_ESPFLASH_BIN="${CARGO_HOME}/bin/cargo-espflash"
    ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/espflash-${ARCH}.zip"
    ESPFLASH_BIN="${CARGO_HOME}/bin/espflash"
    LDPROXY_URL="https://github.com/esp-rs/embuild/releases/latest/download/ldproxy-${ARCH}.zip"
    LDPROXY_BIN="${CARGO_HOME}/bin/ldproxy"
    if [[ "${EXTRA_CRATES}" =~ "sccache" ]]; then
        SCCACHE_URL="https://github.com/mozilla/sccache/releases/latest/download/sccache-${SCCACHE_VERSION}-${ARCH}.tar.gz"
    fi
    SCCACHE_BIN="${CARGO_HOME}/bin/sccache"
    if [[ "${EXTRA_CRATES}" =~ "cargo-generate" ]]; then
        GENERATE_URL="https://github.com/cargo-generate/cargo-generate/releases/latest/download/cargo-generate-${GENERATE_VERSION}-${ARCH}.tar.gz"
    fi
    GENERATE_BIN="${CARGO_HOME}/bin/cargo-generate"
    WOKWI_SERVER_URL="https://github.com/MabezDev/wokwi-server/releases/latest/download/wokwi-server-${ARCH}.zip"
    WOKWI_SERVER_BIN="${CARGO_HOME}/bin/wokwi-server"
    WEB_FLASH_URL="https://github.com/bjoernQ/esp-web-flash-server/releases/latest/download/web-flash-${ARCH}.zip"
    WEB_FLASH_BIN="${CARGO_HOME}/bin/web-flash"
elif [[ ${ARCH} == "x86_64-unknown-linux-gnu" ]]; then
    GCC_ARCH="linux-amd64"
    LLVM_ARCH="linux-amd64"
    CARGO_ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash-${ARCH}.zip"
    CARGO_ESPFLASH_BIN="${CARGO_HOME}/bin/cargo-espflash"
    ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/espflash-${ARCH}.zip"
    ESPFLASH_BIN="${CARGO_HOME}/bin/espflash"
    LDPROXY_URL="https://github.com/esp-rs/embuild/releases/latest/download/ldproxy-${ARCH}.zip"
    LDPROXY_BIN="${CARGO_HOME}/bin/ldproxy"
    # if [[ "${EXTRA_CRATES}" =~ "cargo-generate" ]]; then
    #     GENERATE_URL="https://github.com/cargo-generate/cargo-generate/releases/latest/download/cargo-generate-${GENERATE_VERSION}-${ARCH}.tar.gz"
    # fi
    # GENERATE_BIN="${CARGO_HOME}/bin/cargo-generate"
    WOKWI_SERVER_URL="https://github.com/MabezDev/wokwi-server/releases/latest/download/wokwi-server-${ARCH}.zip"
    WOKWI_SERVER_BIN="${CARGO_HOME}/bin/wokwi-server"
    WEB_FLASH_URL="https://github.com/bjoernQ/esp-web-flash-server/releases/latest/download/web-flash-${ARCH}.zip"
    WEB_FLASH_BIN="${CARGO_HOME}/bin/web-flash"
elif [[ ${ARCH} == "aarch64-unknown-linux-gnu" ]]; then
    GCC_ARCH="linux-arm64"
    LLVM_ARCH="linux-arm64"
    MINIFIED_LLVM="YES"
    # if [[ "${EXTRA_CRATES}" =~ "cargo-generate" ]]; then
    #     GENERATE_URL="https://github.com/cargo-generate/cargo-generate/releases/latest/download/cargo-generate-${GENERATE_VERSION}-${ARCH}.tar.gz"
    # fi
    # GENERATE_BIN="${CARGO_HOME}/bin/cargo-generate"
    CARGO_ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash-${ARCH}.zip"
    CARGO_ESPFLASH_BIN="${CARGO_HOME}/bin/cargo-espflash"
    ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/espflash-${ARCH}.zip"
    ESPFLASH_BIN="${CARGO_HOME}/bin/espflash"
elif [[ ${ARCH} == "x86_64-pc-windows-msvc" ]]; then
    GCC_ARCH="win64"
    LLVM_ARCH="win64"
    CARGO_ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash-${ARCH}.zip"
    CARGO_ESPFLASH_BIN="${CARGO_HOME}/bin/cargo-espflash.exe"
    ESPFLASH_URL="https://github.com/esp-rs/espflash/releases/latest/download/espflash-${ARCH}.zip"
    ESPFLASH_BIN="${CARGO_HOME}/bin/espflash.exe"
    LDPROXY_URL="https://github.com/esp-rs/embuild/releases/latest/download/ldproxy-${ARCH}.zip"
    LDPROXY_BIN="${CARGO_HOME}/bin/ldproxy.exe"
    if [[ "${EXTRA_CRATES}" =~ "sccache" ]]; then
        SCCACHE_URL="https://github.com/mozilla/sccache/releases/latest/download/sccache-${SCCACHE_VERSION}-${ARCH}.tar.gz"
    fi
    SCCACHE_BIN="${CARGO_HOME}/bin/sccache"
    if [[ "${EXTRA_CRATES}" =~ "cargo-generate" ]]; then
        GENERATE_URL="https://github.com/cargo-generate/cargo-generate/releases/latest/download/cargo-generate-${GENERATE_VERSION}-${ARCH}.tar.gz"
    fi
    GENERATE_BIN="${CARGO_HOME}/bin/cargo-generate.exe"
    WOKWI_SERVER_URL="https://github.com/MabezDev/wokwi-server/releases/latest/download/wokwi-server-${ARCH}.zip"
    WOKWI_SERVER_BIN="${CARGO_HOME}/bin/wokwi-server.exe"
    WEB_FLASH_URL="https://github.com/bjoernQ/esp-web-flash-server/releases/latest/download/web-flash-${ARCH}.zip"
    WEB_FLASH_BIN="${CARGO_HOME}/bin/web-flash.exe"
fi

echo "Processing toolchain for ${ARCH} - operation: ${INSTALLATION_MODE}"

RUST_DIST="rust-${TOOLCHAIN_VERSION}-${ARCH}"
RUST_SRC_DIST="rust-src-${TOOLCHAIN_VERSION}"
LLVM_FILE="llvm-${LLVM_VERSION}-${LLVM_ARCH}.tar.xz"
if [[ "${MINIFIED_LLVM}" == "YES" ]]; then
    LLVM_FILE="libs_${LLVM_FILE}"
fi
LLVM_DIST_URL="${LLVM_DIST_MIRROR}/${LLVM_FILE}"
IDF_TOOLS_PATH="${IDF_TOOLS_PATH:-${HOME}/.espressif}"
IDF_TOOL_GCC_PATH=""
IDF_TOOL_XTENSA_ELF_CLANG="${IDF_TOOLS_PATH}/tools/xtensa-esp32-elf-clang/${LLVM_VERSION}-${ARCH}/esp-clang"

RUST_DIST_URL="https://github.com/esp-rs/rust-build/releases/download/v${TOOLCHAIN_VERSION}/${RUST_DIST}.tar.xz"

if [[ "${INSTALLATION_MODE}" == "uninstall" ]] || [[ "${INSTALLATION_MODE}" == "reinstall" ]]; then
    echo "Removing:"

    echo " - ${TOOLCHAIN_DESTINATION_DIR}"
    rm -rf "${TOOLCHAIN_DESTINATION_DIR}"

    echo " - ${IDF_TOOL_XTENSA_ELF_CLANG}"
    rm -rf "${IDF_TOOL_XTENSA_ELF_CLANG}"

    if [[ "${CLEAR_DOWNLOAD_CACHE}" == "YES" ]]; then
        clear_download_cache
    fi

    if [[ "${INSTALLATION_MODE}" == "uninstall" ]]; then
        exit 0
    fi
fi

if [[ "${BUILD_TARGET}" =~ esp32s[2|3] || "${BUILD_TARGET}" =~ esp32[,|\ ] || "${BUILD_TARGET}" =~ esp32$ ]]; then
    install_rust_xtensa_toolchain
    IS_XTENSA_INSTALLED=1
    install_llvm_clang
fi

if [[ -n "${ESP_IDF_VERSION}" ]]; then
    install_esp_idf
elif [[ "${BUILD_TARGET}" =~ "esp32c3" ]]; then
    install_gcc "riscv32-esp-elf"
fi
install_extra_crates

if [[ "${CLEAR_DOWNLOAD_CACHE}" == "YES" ]]; then
    clear_download_cache
fi

printf "\n IMPORTANT!"
printf "\n The following environment variables need to be updated:\n"
if [[ ${IS_XTENSA_INSTALLED} -eq 1 ]]; then
    echo export LIBCLANG_PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/lib/\"
fi
if [[ -n "${ESP_IDF_VERSION}" ]]; then
    echo "export IDF_TOOLS_PATH=${IDF_TOOLS_PATH}"
    echo ". ${IDF_PATH}/export.sh"
else
    echo export PATH=\"${IDF_TOOL_GCC_PATH}:\$PATH\"
fi
PROFILE_NAME="your default shell"
if grep -q "zsh" <<<"$SHELL"; then
    PROFILE_NAME=~/.zshrc
elif grep -q "bash" <<<"$SHELL"; then
    PROFILE_NAME=~/.bashrc
fi
printf "\n If you want to activate the environment required for Rust in ESP SoC's in every terminal session automatically, you can add the previous commands to \"$PROFILE_NAME\""
printf "\n However, it is not recommended, as doing so activates the virtual environment in every terminal session (including those where is not needed), defeating the purpose of the virtual environment and likely affecting other software."

if [[ -n "${EXPORT_FILE:-}" ]]; then
    printf "\n The recommended approach is to source the export file: \". ./${EXPORT_FILE}\""
    printf "\n Note: This should be done in every terminal session.\n"
    echo -n "" >"${EXPORT_FILE}"
    if [[ ${IS_XTENSA_INSTALLED} -eq 1 ]]; then
        echo export LIBCLANG_PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/lib/\" >>"${EXPORT_FILE}"
    fi
    if [[ -n "${ESP_IDF_VERSION}" ]]; then
        echo "export IDF_TOOLS_PATH=${IDF_TOOLS_PATH}" >>"${EXPORT_FILE}"
        echo ". ${IDF_PATH}/export.sh /dev/null 2>&1" >>"${EXPORT_FILE}"
    else
        echo export PATH=\"${IDF_TOOL_GCC_PATH}:\$PATH\" >>"${EXPORT_FILE}"
    fi
    if [[ ${IS_SCCACHE_INSTALLED} -eq 1 ]]; then
        echo "export CARGO_INCREMENTAL=0" >>"${EXPORT_FILE}"
        echo "export RUSTC_WRAPPER=$(which sccache)" >>"${EXPORT_FILE}"
    fi
else
    PROFILE_NAME="your default shell"
    if grep -q "zsh" <<<"$SHELL"; then
        PROFILE_NAME=~/.zshrc
    elif grep -q "bash" <<<"$SHELL"; then
        PROFILE_NAME=~/.bashrc
    fi
    echo "Add following command to $PROFILE_NAME"
    if [[ ${IS_XTENSA_INSTALLED} -eq 1 ]]; then
        echo export LIBCLANG_PATH=\"${IDF_TOOL_XTENSA_ELF_CLANG}/lib/\"
    fi
    if [[ -n "${ESP_IDF_VERSION}" ]]; then
        echo "export IDF_TOOLS_PATH=${IDF_TOOLS_PATH}"
        echo "source ${IDF_PATH}/export.sh"
    else
        echo export PATH=\"${IDF_TOOL_GCC_PATH}:\$PATH\"
    fi
    if [[ ${IS_SCCACHE_INSTALLED} -eq 1 ]]; then
        echo "export CARGO_INCREMENTAL=0"
        echo "export RUSTC_WRAPPER=$(which sccache)"
    fi
fi
