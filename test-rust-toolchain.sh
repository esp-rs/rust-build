#!/usr/bin/env bash

set -e

# Default values
TOOLCHAIN_VERSION="1.69.0.0"
if [ -z "${RUSTUP_HOME}" ]; then
  RUSTUP_HOME="${HOME}/.rustup"
fi
TOOLCHAIN_PREFIX="esp"
BUILD_TARGET="xtensa-esp32-espidf" # all, xtensa-esp32-espidf, xtensa-esp32s2-espidf, riscv32imc-esp-espidf
INSTALLATION_MODE="reinstall"      # install, reinstall, uninstall, skip
LLVM_VERSION="esp-14.0.0-20220415"
TEST_MODE="compile" # compile, flash, monitor
TEST_PORT="/dev/ttyUSB0"
FEATURES="" # space separated features of the project
CLEAR_CACHE="no"
EXTRA_CRATES="ldproxy"
export ESP_IDF_VERSION="release/v4.4"
PROJECT="rust-esp32-std-demo"
PROJECT_USER="ivmarkov"
PROJECT_REPO="https://github.com/${PROJECT_USER}/${PROJECT}.git"

# Process positional arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  -c | --extra-crates)
    EXTRA_CRATES="$2"
    shift # past argument
    shift # past value
    ;;
  -d | --test-port)
    TEST_PORT="$2"
    shift # past argument
    shift # past value
    ;;
  -f | --features)
    FEATURES="$2"
    shift # past argument
    shift # past value
    ;;
  -e | --esp-idf)
    export ESP_IDF_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
  -n | --toolchain-prefix)
    TOOLCHAIN_PREFIX="$2"
    shift # past argument
    shift # past value
    ;;
  -b | --target)
    BUILD_TARGET="$2"
    shift # past argument
    shift # past value
    ;;
  -i | --installation-mode)
    INSTALLATION_MODE="$2"
    shift # past argument
    shift # past value
    ;;
  -l | --llvm-version)
    LLVM_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
  -m | --test-mode)
    TEST_MODE="$2"
    shift # past argument
    shift # past value
    ;;
  -p | --project)
    PROJECT="$2"
    shift # past argument
    shift # past value
    ;;
  -t | --toolchain-version)
    TOOLCHAIN_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
  -g | --project-repo)
    PROJECT_REPO="$2"
    shift # past argument
    shift # past value
    ;;
  -u | --project-user)
    PROJECT_USER="$2"
    shift # past argument
    shift # past value
    ;;
  -x | --clear-cache)
    CLEAR_CACHE="YES"
    shift
    ;;
  *)                   # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift              # past argument
    ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

echo "Processing configuration:"
echo "--clear-cache        = ${CLEAR_CACHE}"
echo "--features           = ${FEATURES}"
echo "--esp-idf            = ${ESP_IDF_VERSION}"
echo "--extra-crates       = ${EXTRA_CRATES}"
echo "--installation-mode  = ${INSTALLATION_MODE}"
echo "--project            = ${PROJECT}"
echo "--project-repo       = ${PROJECT_REPO}"
echo "--target             = ${BUILD_TARGET}"
echo "--test-mode          = ${TEST_MODE}"
echo "--test-port          = ${TEST_PORT}"
echo "--toolchain-prefix   = ${TOOLCHAIN_PREFIX}"
echo "--toolchain-version  = ${TOOLCHAIN_VERSION}"

TOOLCHAIN_NAME="${TOOLCHAIN_PREFIX}-${TOOLCHAIN_VERSION}"
EXPORT_FILE="export-rust-${TOOLCHAIN_NAME}.sh"

function source_cargo() {
  if [ ! -z "${CARGO_HOME}" ]; then
    source ${CARGO_HOME}/env
  else
    source ${HOME}/.cargo/env
  fi
}

if [ "${INSTALLATION_MODE}" != "skip" ]; then
  ./install-rust-toolchain.sh --installation-mode ${INSTALLATION_MODE} \
    --clear-cache "${CLEAR_CACHE}" \
    --extra-crates "${EXTRA_CRATES}" \
    --export-file "${EXPORT_FILE}" \
    --llvm-version "${LLVM_VERSION}" \
    --toolchain-destination "${RUSTUP_HOME}/toolchains/${TOOLCHAIN_NAME}" \
    --toolchain-version ${TOOLCHAIN_VERSION}
fi

source "./${EXPORT_FILE}"
command -v cargo || source_cargo

# Prepare project
if [ "${CLEAR_CACHE}" == "YES" ]; then
  rm -rf "${PROJECT}"
fi

if [ ! -d "${PROJECT}" ]; then
  git clone ${PROJECT_REPO} ${PROJECT}
fi

cd "${PROJECT}"

# Left over from other target might cause failure in the build, it's better to start from the scratch
cargo clean

# Project specific setup
case ${PROJECT} in
rust-esp32-std-demo)
  if [ -z "${RUST_ESP32_STD_DEMO_WIFI_SSID}" ]; then
    export RUST_ESP32_STD_DEMO_WIFI_SSID="rust"
    export RUST_ESP32_STD_DEMO_WIFI_PASS="for-esp32"
  fi
  ;;
esac

if [ "${BUILD_TARGET}" == "all" ]; then
  for TARGET in xtensa-esp32-espidf xtensa-esp32s2-espidf riscv32imc-esp-espidf; do
    echo "Building target: ${TARGET}"
    cargo +${TOOLCHAIN_NAME} build --target ${TARGET} --release --features "${FEATURES}"
  done
else
  echo "cargo +${TOOLCHAIN_NAME} build --target ${BUILD_TARGET}" --features "${FEATURES}"
  cargo +${TOOLCHAIN_NAME} build --target "${BUILD_TARGET}" --release --features "${FEATURES}"
  ELF_IMAGE="target/${BUILD_TARGET}/release/${RUST_STD_DEMO}"
  if [ "${TEST_MODE}" == "flash" ]; then
    cargo +${TOOLCHAIN_NAME} espflash --target "${BUILD_TARGET}" --release --features ${FEATURES} "${TEST_PORT}"
  elif [ "${TEST_MODE}" == "monitor" ]; then
    cargo +${TOOLCHAIN_NAME} espflash --monitor --target "${BUILD_TARGET}" --release --features "${FEATURES}" "${TEST_PORT}"
  fi
fi
