#!/bin/bash

# Default values
TOOLCHAIN_VERSION="1.56.0-dev"
if [ -z "${RUSTUP_HOME}" ]; then
    RUSTUP_HOME="${HOME}/.rustup"
fi
TOOLCHAIN_PREFIX="esp"
BUILD_TARGET="xtensa-esp32-espidf"
INSTALLATION_MODE="install" # reinstall, uninstall

# Process positional arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -t|--toolchain-version)
      TOOLCHAIN_VERSION="$2"
      shift # past argument
      shift # past value
      ;;
    -n|--toolchain-prefix)
      TOOLCHAIN_PREFIX="$2"
      shift # past argument
      shift # past value
      ;;
    -b|--target)
      BUILD_TARGET="$2"
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
echo "--installation-mode  = ${INSTALLATION_MODE}"
echo "--target             = ${BUILD_TARGET}"
echo "--toolchain-prefix   = ${TOOLCHAIN_PREFIX}"
echo "--toolchain-version  = ${TOOLCHAIN_VERSION}"

TOOLCHAIN_NAME="${TOOLCHAIN_PREFIX}-${TOOLCHAIN_VERSION}"
EXPORT_FILE="export-rust-${TOOLCHAIN_NAME}.sh"

./install-rust-toolchain.sh --installation-mode ${INSTALLATION_MODE} \
    --export-file "${EXPORT_FILE}" \
    --toolchain-destination "${RUSTUP_HOME}/toolchains/${TOOLCHAIN_NAME}" \
    --toolchain-version ${TOOLCHAIN_VERSION}
. "./${EXPORT_FILE}"

RUST_STD_DEMO="rust-esp32-std-demo"

if [ ! -d "${RUST_STD_DEMO}" ]; then
    git clone https://github.com/ivmarkov/${RUST_STD_DEMO}.git
fi

cd "${RUST_STD_DEMO}"
export RUST_ESP32_STD_DEMO_WIFI_SSID="rust"
export RUST_ESP32_STD_DEMO_WIFI_PASS="for-esp32"

if [ "${BUILD_TARGET}" == "all" ]; then
  cargo +${TOOLCHAIN_NAME} build --target xtensa-esp32-espidf --installation-mode reinstall
  cargo +${TOOLCHAIN_NAME} build --target xtensa-esp32s2-espidf
  cargo +${TOOLCHAIN_NAME} build --target riscv32imc-esp-espidf
else
  cargo +${TOOLCHAIN_NAME} build --target ${BUILD_TARGET}
fi
