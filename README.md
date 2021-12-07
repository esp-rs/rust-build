# rust-build

This repository contains:
- workflows for building Rust fork [esp-rs/rust](https://github.com/esp-rs/rust) with Xtensa support
- binary artifacts in [Releases](https://github.com/esp-rs/rust-build/releases)

## Quick start

The installation process of ready to use custom build of Rust and LLVM:

* [macOS Big Sur M1, macOS Big Sur x86_64, Linux x86_64](#rust-on-xtensa-installation-for-macos-and-linux)
* [Windows 10 x64](#rust-on-xtensa-installation-for-windows-x64)
* [Podman/Docker](#rust-with-podman-or-docker)
* Not supported: Linux arm64 - missing support in ESP-IDF - https://github.com/espressif/esp-idf/issues/6475

## Installation

### Rust on Xtensa Installation for macOS and Linux

Following instructions are specific for ESP32 and ESP32-S series based on Xtensa architecture.

Instructions for ESP-C series based on RISC-V architecture are described in document for [ESP32-C3](#esp32-c3).

Tested OS: macOS Big Sur M1, macOS Big Sur x86_64, Linux x86_64

#### Prerequisites

- rustup - https://rustup.rs/

#### Installation commands

```sh
./install-rust-toolchain.sh
```

Export variables displayed at the end of the script.

Installation of different version of toolchain:

```
./install-rust-toolchain.sh --toolchain-version 1.57.0.0 --export-file export-esp-rust.sh
source ./export-esp-rust.sh
```

#### Get source code of examples

```
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

### Rust on Xtensa Installation for Windows x64

Following instructions are specific for ESP32 and ESP32-S series based on Xtensa architecture.

Instructions for ESP-C series based on RISC-V architecture are described in document for [ESP32-C3](esp32-c3).

Tested OS: Windows 10 x64

#### Prerequisites

- Visual Studio - installed with option Desktop development with C++ - components: MSVCv142 - VS2019 C++ x86/64 build tools, Windows 10 SDK

#### Installation commands for PowerShell

```sh
./Install-RustToolchain.ps1
```

Export variables displayed at the end of the output from the script.

Installation of different version of toolchain:

```
./Install-RustToolchain.sh --toolchain-version 1.57.0.0 --export-file Export-EspRust.ps1
source ./Export-EspRust.ps1
```

#### Get source code of examples

```sh
Invoke-WebRequest https://github.com/espressif/rust-esp32-example/archive/refs/heads/main.zip -OutFile rust-esp32-example.zip
Expand-Archive rust-esp32-example.zip
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

### ESP32-C3

Install the RISCV target for Rust:

```sh
rustup target add riscv32i-unknown-none-elf
```

### Rust with Podman or Docker

Alternatively you might build the project in the container where image already contains pre-installed Rust and ESP-IDF.

Podman example with mapping multiple /dev/ttyUSB from host computer to the container:

```
podman run --device /dev/ttyUSB0 --device /dev/ttyUSB1 -it espressif/idf-rust-examples
```

Docker (does not support flashing from container):

```
docker run -it espressif/idf-rust-examples
```

Then follow instructions displayed on the screen.


