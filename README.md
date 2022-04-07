# rust-build

This repository contains:
- workflows for building Rust fork [esp-rs/rust](https://github.com/esp-rs/rust) with Xtensa support
- binary artifacts in [Releases](https://github.com/esp-rs/rust-build/releases)

## Quick start

The installation process of ready to use custom build of Rust and LLVM:

* [macOS M1 aarch64, macOS x86_64](#rust-on-xtensa-installation-for-macos)
* [Linux x86_64, Linux aarch64](#rust-on-xtensa-installation-for-linux)
* [Windows 10, 11 x86_64](#rust-on-xtensa-installation-for-windows-x64)
* [Podman/Docker](#rust-with-podman-or-docker)

## Installation

### Rust on Xtensa Installation for macOS

Following instructions are specific for ESP32 and ESP32-S series based on Xtensa architecture.

Instructions for ESP-C series based on RISC-V architecture are described in document for [ESP32-C3](#esp32-c3).

#### Prerequisites

- rustup - https://rustup.rs/

#### Installation commands

```sh
./install-rust-toolchain.sh
```

Export variables displayed at the end of the script.

Installation of different version of toolchain:

```
./install-rust-toolchain.sh --toolchain-version 1.60.0.0 --export-file export-esp-rust.sh
source ./export-esp-rust.sh
```

### Rust on Xtensa Installation for Linux

Following instructions are specific for ESP32 and ESP32-S series based on Xtensa architecture.

Instructions for ESP-C series based on RISC-V architecture are described in document for [ESP32-C3](#esp32-c3).

#### Prerequisites

- rustup - https://rustup.rs/
- dependencies (command for Ubuntu/Debian):

```sh
apt-get install -y git curl gcc ninja-build cmake libudev-dev python3 python3-pip libusb-1.0-0 libssl-dev pkg-config libtinfo5
```

#### Installation commands

```sh
./install-rust-toolchain.sh
```

Export variables displayed at the end of the script.

Installation of different version of toolchain:

```
./install-rust-toolchain.sh --toolchain-version 1.60.0.0 --export-file export-esp-rust.sh
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

#### Prerequisites

- Visual Studio - installed with option Desktop development with C++ - components: MSVCv142 - VS2019 C++ x86/64 build tools, Windows 10 SDK

![Visual Studio Installer - configuration](support/img/rust-windows-requirements.png?raw=true)

Installation of prerequisites with Chocolatey (run PowerShell as Administrator):

```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install cmake git microsoft-visual-cpp-build-tools ninja windows-sdk-10.0
```

#### Installation commands for PowerShell

```sh
./Install-RustToolchain.ps1
```

Export variables displayed at the end of the output from the script.

Installation of different version of toolchain:

```
./Install-RustToolchain.sh --toolchain-version 1.60.0.0 --export-file Export-EspRust.ps1
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

Alternatively, you might build the project in the container where the image already contains pre-installed Rust and ESP-IDF.

There are two different images published to Dockerhub: 
- [idf-rust](https://hub.docker.com/r/espressif/idf-rust) - contains only the toolchain.
- [idf-rust-examples](https://hub.docker.com/r/espressif/idf-rust-examples) - includes two examples: [rust-esp32-example](https://github.com/espressif/rust-esp32-example) and [rust-esp32-std-demo](https://github.com/ivmarkov/rust-esp32-std-demo).

Podman example with mapping multiple /dev/ttyUSB from host computer to the container:

```
podman run --device /dev/ttyUSB0 --device /dev/ttyUSB1 -it docker.io/espressif/idf-rust-examples
```

Docker (does not support flashing from container):

```
docker run -it espressif/idf-rust-examples
```

If you are using the `idf-rust-examples` image, instructions will be displayed on the screen.


