# rust-build

This repository contains:
- workflows for building Rust fork [esp-rs/rust](https://github.com/esp-rs/rust) with Xtensa support
- binary artifacts in [Releases](https://github.com/esp-rs/rust-build/releases)

## Table of Contents

- [Xtensa Installation](#xtensa-installation)
  - [Linux and macOS](#linux-and-macos)
    - [Prerequisites](#prerequisites)
    - [Installation commands](#installation-commands)
  - [Windows x64](#windows-x64)
    - [Prerequisites](#prerequisites-1)
    - [Installation commands for PowerShell](#installation-commands-for-powershell)
- [RiscV Installation](#riscv-installation)
- [Building projects](#building-projects)
    - [Cargo first approach](#cargo-first-approach)
    - [Idf first approach](#idf-first-approach)
- [Podman/Docker Rust ESP environment](#podmandocker-rust-esp-environment)
- [Devcontainers](#devcontainers)

## Xtensa Installation

### Linux and macOS

Following instructions are specific for ESP32 and ESP32-S series based on Xtensa architecture.

Instructions for ESP-C series based on RISC-V architecture are described in [RiscV section](#riscv-installation).

#### Prerequisites
- Linux:
  - dependencies (command for Ubuntu/Debian):
    ```sh
    apt-get install -y git curl gcc ninja-build cmake libudev-dev \
      python3 python3-pip libusb-1.0-0 libssl-dev pkg-config libtinfo5
    ```
No prerequisites are needed for macOS
#### Installation commands

```sh
./install-rust-toolchain.sh
```
> Run `./install-rust-toolchain.sh --help` for more information about arguments.

Export variables are displayed at the end of the script.

### Windows x64

Following instructions are specific for ESP32 and ESP32-S series based on Xtensa architecture.

Instructions for ESP-C series based on RISC-V architecture are described  in [RiscV section](#riscv-installation).

#### Prerequisites

- Visual Studio - installed with option Desktop development with C++ - components: MSVCv142 - VS2019 C++ x86/64 build tools, Windows 10 SDK

![Visual Studio Installer - configuration](support/img/rust-windows-requirements.png?raw=true)

Installation of prerequisites with Chocolatey (run PowerShell as Administrator):

```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install cmake git ninja visualstudio2022-workload-vctools windows-sdk-10.0
```

#### Installation commands for PowerShell

```sh
./Install-RustToolchain.ps1
```

Export variables are displayed at the end of the output from the script.

Installation of different version of toolchain:

```
./Install-RustToolchain.sh --toolchain-version 1.60.0.0 --export-file Export-EspRust.ps1
source ./Export-EspRust.ps1
```

## RiscV Installation
Following instructions are specific for ESP32-C based on RiscV architecture.

Install the RISCV target for Rust:

```sh
rustup target add riscv32i-unknown-none-elf
```

## Building projects
#### Cargo first approach
1. Get example source code
    ```sh
    git clone https://github.com/ivmarkov/rust-esp32-std-demo.git
    cd rust-esp32-std-demo/
    ```
2. Build and flash:
    ```sh
    cargo espflash --target <TARGET> <SERIAL>
    ```
    Where `TARGET` can be:
    - `xtensa-esp32-espidf` for the ESP32(Xtensa architecture). [Default]
    - `xtensa-esp32s2-espidf` for the ESP32-S2(Xtensa architecture).
    - `xtensa-esp32s3-espidf` for the ESP32-S3(Xtensa architecture).
    - `riscv32imc-esp-espidf` for the ESP32-C3(RiscV architecture).

    And `SERIAL` is the serial port connected to the target device.
    > [cargo-espflash](https://github.com/esp-rs/espflash/tree/master/cargo-espflash) also allows opening a serial monitor after flashing with `--monitor` option, see [Usage](https://github.com/esp-rs/espflash/tree/master/cargo-espflash#usage) section for more information about arguments.
#### Idf first approach

1. Get example source code
    ```sh
    git clone https://github.com/espressif/rust-esp32-example.git
    cd rust-esp32-example-main
    ```
2. Select architecture for the build
    ```sh
    idf.py set-target <TARGET>
    ```
    Where `TARGET` can be:
    - `esp32` for the ESP32(Xtensa architecture). [Default]
    - `esp32s2` for the ESP32-S2(Xtensa architecture).
    - `esp32s3` for the ESP32-S3(Xtensa architecture).
3. Build and flash
    ```sh
    idf.py build flash
    ```

## Podman/Docker Rust ESP environment

Alternatively, some container images, with pre-installed Rust and ESP-IDF, are published to Dockerhub and can be used to build Rust projects for ESP boards:

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
## Devcontainers

There is also the option to integrate with Visual Studio Code using [remote containers](https://code.visualstudio.com/docs/remote/containers). With this method,
we would have a fully working environment to build projects in Rust for ESP boards
in VScode alongside useful settings and extensions, for more information,
please, refer to [esp-rs-devcontainer](https://github.com/SergioGasquez/esp-rs-devcontainer).
