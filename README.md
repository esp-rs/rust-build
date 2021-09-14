# rust-build

This repository contains:
- workflows for building Rust fork [esp-rs/rust](https://github.com/esp-rs/rust) with Xtensa support
- binary artifacts in [Releases](https://github.com/esp-rs/rust-build/releases)

## Quick start

The installation process of ready to use custom build of Rust and LLVM:

* [macOS Big Sur M1](#rust-on-xtensa-installation-for-macos-m1)
* [macOS Big Sur x64](#rust-on-xtensa-installation-for-macos-x64)
* [Linux x64](#rust-on-xtensa-installation-for-linux-x64)
* [Windows 10 x64](#rust-on-xtensa-installation-for-windows-x64)
* Not supported: Linux arm64 - missing support in ESP-IDF - https://github.com/espressif/esp-idf/issues/6475

## Installation

### Rust on Xtensa Installation for macOS M1

Following instructions are specific for ESP32 and ESP32-S series based on Xtensa architecture.

Instructions for ESP-C series based on RISC-V architecture are described in document for [ESP32-C3](../README.md#esp32-c3).

Tested OS: macOS Big Sur M1

#### Prerequisites

- rustup - https://rustup.rs/

#### Installation commands

```sh
rustup toolchain install nightly

VERSION="1.55.0-dev"
ARCH="aarch64-apple-darwin"
RUST_DIST="rust-${VERSION}-${ARCH}"
RUST_SRC_DIST="rust-src-${VERSION}"
TOOLCHAIN_DESTINATION_DIR="~/.rustup/toolchains/esp"

mkdir -p ${TOOLCHAIN_DESTINATION_DIR}

curl -LO "https://github.com/esp-rs/rust-build/releases/download/v${VERSION}/${RUST_DIST}.tar.xz"
tar xvf ${RUST_DIST}.tar.xz
./${RUST_DIST}/install.sh --destdir=${TOOLCHAIN_DESTINATION_DIR} --prefix="" --without=rust-docs

curl -LO "https://github.com/esp-rs/rust-build/releases/download/v${VERSION}/${RUST_SRC_DIST}.tar.xz"
tar xvf ${RUST_SRC_DIST}.tar.xz
./${RUST_SRC_DIST}/install.sh --destdir=${TOOLCHAIN_DESTINATION_DIR} --prefix="" --without=rust-docs

rustup default esp

curl -O "https://dl.espressif.com/dl/idf-rust/dist/${ARCH}/xtensa-esp32-elf-llvm11_0_0-aarch64-apple-darwin.tar.xz"
tar xf xtensa-esp32-elf-llvm11_0_0-aarch64-apple-darwin.tar.xz
export PATH="`pwd`/xtensa-esp32-elf-clang/bin/:$PATH"

curl -LO "https://github.com/espressif/rust-esp32-example/archive/refs/heads/main.zip"
unzip main.zip
cd rust-esp32-example-main
```

#### Select architecture for the build

For the ESP32 - default (Xtensa architecture):

```sh
idf.py set-target esp32
```

For the ESP32-S2 (Xtensa architecture):

```sh
idf.py set-target esp32s2
```

For the ESP32-S3 (Xtensa architecture):

```sh
idf.py set-target esp32s3
```

#### Build and flash

```sh
idf.py build flash
```

### Rust on Xtensa Installation for macOS x64

Following instructions are specific for ESP32 and ESP32-S series based on Xtensa architecture.

Instructions for ESP-C series based on RISC-V architecture are described in document for [ESP32-C3](../README.md#esp32-c3).

Tested OS: macOS Big Sur x64

#### Prerequisites

- rustup - installed with nightly toolchain - https://rustup.rs/

#### Installation commands

```sh
rustup toolchain install nightly

VERSION="1.55.0-dev"
ARCH="x86_64-apple-darwin"
RUST_DIST="rust-${VERSION}-${ARCH}"
RUST_SRC_DIST="rust-src-${VERSION}"
TOOLCHAIN_DESTINATION_DIR="~/.rustup/toolchains/esp"

mkdir -p ${TOOLCHAIN_DESTINATION_DIR}

curl -LO "https://github.com/esp-rs/rust-build/releases/download/v${VERSION}/${RUST_DIST}.tar.xz"
tar xvf ${RUST_DIST}.tar.xz
./${RUST_DIST}/install.sh --destdir=${TOOLCHAIN_DESTINATION_DIR} --prefix="" --without=rust-docs

curl -LO "https://github.com/esp-rs/rust-build/releases/download/${RUST_SRC_DIST}.tar.xz"
tar xvf ${RUST_SRC_DIST}.tar.xz
./${RUST_SRC_DIST}/install.sh --destdir=${TOOLCHAIN_DESTINATION_DIR} --prefix="" --without=rust-docs

rustup default esp

curl -O "https://dl.espressif.com/dl/idf-rust/dist/${ARCH}/xtensa-esp32-elf-llvm11_0_0-x86_64-apple-darwin.tar.xz"
tar xf xtensa-esp32-elf-llvm11_0_0-x86_64-apple-darwin.tar.xz
export PATH="`pwd`/xtensa-esp32-elf-clang/bin/:$PATH"

curl -LO "https://github.com/espressif/rust-esp32-example/archive/refs/heads/main.zip"
unzip main.zip
cd rust-esp32-example-main
```

#### Select architecture for the build

For the ESP32 - default (Xtensa architecture):

```sh
idf.py set-target esp32
```

For the ESP32-S2 (Xtensa architecture):

```sh
idf.py set-target esp32s2
```

For the ESP32-S3 (Xtensa architecture):

```sh
idf.py set-target esp32s3
```

#### Build and flash

```sh
idf.py build flash
```

### Rust on Xtensa Installation for Linux x64

Following instructions are specific for ESP32 and ESP32-S series based on Xtensa architecture.

Instructions for ESP-C series based on RISC-V architecture are described in document for [ESP32-C3](../README.md#esp32-c3).

Tested OS: Ubuntu 18 x64, Ubuntu 20 x64, Mint 20 x64, OpenSUSE Thumbleweed

#### Prerequisites

- rustup - installed with nightly toolchain - https://rustup.rs/

#### Installation commands

```sh
sudo apt install gcc wget xz-utils

rustup toolchain install nightly

VERSION="1.55.0-dev"
ARCH="x86_64-unknown-linux-gnu"
RUST_DIST="rust-${VERSION}-${ARCH}"
RUST_SRC_DIST="rust-src-${VERSION}"
TOOLCHAIN_DESTINATION_DIR="~/.rustup/toolchains/esp"

mkdir -p ${TOOLCHAIN_DESTINATION_DIR}

wget https://github.com/esp-rs/rust-build/releases/download/v${VERSION}/${RUST_DIST}.tar.xz
tar xvf ${RUST_DIST}.tar.xz
./${RUST_DIST}/install.sh --destdir=${TOOLCHAIN_DESTINATION_DIR} --prefix="" --without=rust-docs

wget https://github.com/esp-rs/rust-build/releases/download/${RUST_SRC_DIST}.tar.xz
tar xvf ${RUST_SRC_DIST}.tar.xz
./${RUST_SRC_DIST}/install.sh --destdir=${TOOLCHAIN_DESTINATION_DIR} --prefix="" --without=rust-docs

rustup default esp

wget https://github.com/espressif/llvm-project/releases/download/esp-12.0.1-20210823/xtensa-esp32-elf-llvm12_0_1-esp-12.0.1-20210823-linux-amd64.tar.xz
tar xf xtensa-esp32-elf-llvm12_0_1-esp-12.0.1-20210823-linux-amd64.tar.xz
export PATH="`pwd`/xtensa-esp32-elf-clang/bin/:$PATH"

wget --continue https://github.com/espressif/rust-esp32-example/archive/refs/heads/main.zip
unzip main.zip
cd rust-esp32-example-main
```

#### Select architecture for the build

For the ESP32 - default (Xtensa architecture):

```sh
idf.py set-target esp32
```

For the ESP32-S2 (Xtensa architecture):

```sh
idf.py set-target esp32s2
```

For the ESP32-S3 (Xtensa architecture):

```sh
idf.py set-target esp32s3
```

#### Build and flash

```sh
idf.py build flash
```

### Rust on Xtensa Installation for Windows x64

Following instructions are specific for ESP32 and ESP32-S series based on Xtensa architecture.

Instructions for ESP-C series based on RISC-V architecture are described in document for [ESP32-C3](../README.md#esp32-c3).

Tested OS: Windows 10 x64

#### Prerequisites

- Visual Studio - installed with option Desktop development with C++
- rustup - installed with nightly toolchain - https://rustup.rs/
- Chocolatey - https://chocolatey.org/

#### Installation commands for PowerShell

```sh
choco install 7zip

rustup toolchain install nightly

$Version="1.55.0-dev"
$Arch="x86_64-pc-windows-msvc"
$RustDist="rust-${VERSION}-${ARCH}"

mkdir -p ~\.rustup\toolchains\ -ErrorAction SilentlyContinue
pushd ~\.rustup\toolchains\

Invoke-WebRequest "https://github.com/esp-rs/rust-build/releases/download/v${VERSION}/${RUST_DIST}.tar.xz" -OutFile "${RustDist}.zip"
7z x .\${RustDist}.zip
popd

rustup default esp

Invoke-WebRequest https://github.com/espressif/llvm-project/releases/download/esp-12.0.1-20210823/xtensa-esp32-elf-llvm12_0_1-esp-12.0.1-20210823-win64.zip -OutFile xtensa-esp32-elf-llvm12_0_1-esp-12.0.1-20210823-win64.zip
7z x xtensa-esp32-elf-llvm12_0_1-esp-12.0.1-20210823-win64.zip
$env:LIBCLANG_PATH=Join-Path -Path (Get-Location) -ChildPath xtensa-esp32-elf-clang\bin
$env:PATH+=";$env:LIBCLANG_PATH"

Invoke-WebRequest https://github.com/espressif/rust-esp32-example/archive/refs/heads/main.zip -OutFile rust-esp32-example.zip
7z x rust-esp32-example.zip
cd rust-esp32-example-main
```

#### Select architecture for the build

For the ESP32 - default (Xtensa architecture):

```sh
idf.py set-target esp32
```

For the ESP32-S2 (Xtensa architecture):

```sh
idf.py set-target esp32s2
```

For the ESP32-S3 (Xtensa architecture):

```sh
idf.py set-target esp32s3
```

#### Build and flash

```sh
idf.py build flash
```

