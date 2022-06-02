# rust-build

This repository contains:

- Workflows for building a Rust fork [esp-rs/rust](https://github.com/esp-rs/rust) with Xtensa support
- Binary artifacts in [Releases](https://github.com/esp-rs/rust-build/releases)
- An [installation script](install-rust-toolchain.sh) to locally install a pre-compiled nightly ESP32 toolchain

## Table of Contents

- [rust-build](#rust-build)
  - [Table of Contents](#table-of-contents)
  - [Xtensa Installation](#xtensa-installation)
    - [Download installer](#download-installer)
      - [Download installer in Bash](#download-installer-in-bash)
      - [Download installer in PowerShell](#download-installer-in-powershell)
    - [Linux and macOS](#linux-and-macos)
      - [Prerequisites](#prerequisites)
      - [Installation commands](#installation-commands)
    - [Windows x64](#windows-x64)
      - [Prerequisites](#prerequisites-1)
      - [Installation commands for PowerShell](#installation-commands-for-powershell)
  - [RISC-V Installation](#riscv-installation)
  - [Building projects](#building-projects)
    - [Cargo first approach](#cargo-first-approach)
    - [Idf first approach](#idf-first-approach)
  - [Podman/Docker Rust ESP environment](#podmandocker-rust-esp-environment)
  - [Dev-Containers](#dev-containers)

## Xtensa Installation

Download installer from Release section: [https://github.com/esp-rs/rust-build/releases/tag/v1.61.0.0]

### Download installer

#### Download installer in Bash

```bash
curl -LO https://github.com/esp-rs/rust-build/releases/download/v1.61.0.0/install-rust-toolchain.sh
chmod a+x install-rust-toolchain.sh
```

#### Download installer in PowerShell

```powershell
Invoke-WebRequest 'https://github.com/esp-rs/rust-build/releases/download/v1.61.0.0/Install-RustToolchain.ps1' -OutFile .\Install-RustToolchain.ps1
```

### Linux and macOS

Following instructions are specific for ESP32 and ESP32-S series based on Xtensa architecture.

Instructions for ESP-C series based on RISC-V architecture are described in [RISC-V section](#riscv-installation).

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
git clone https://github.com/esp-rs/rust-build.git
cd rust-build
./install-rust-toolchain.sh
```

Run `./install-rust-toolchain.sh --help` for more information about arguments.

Export variables are displayed at the end of the script.
> **Note**
> If the export variables are added into the shell startup script, the shell may need to be refreshed.

Installation of different version of toolchain:

```
./install-rust-toolchain.sh --toolchain-version 1.61.0.0 --export-file export-esp-rust.sh
source export-esp-rust.sh
```

#### Arguments
- `-b|--build-target`: Comma separated list of targets [`esp32,esp32s2,esp32s3,esp32c3`]. Defaults to: `esp32,esp32s2,esp32s3`
- `-c|--cargo-home`: Cargo path.
- `-d|--toolchain-destination`: Toolchain instalation folder. Defaults to: `<rustup_home>/toolchains/esp`
- `-e|--extra-crates`: Extra crates to install. Defaults to: `ldproxy cargo-espflash`
- `-f|--export-file`: Destination of the export file generated.
- `-i|--installation-mode`: Installation mode: [`install, reinstall, uninstall`]. Defaults to: `install`
- `-l|--llvm-version`: LLVM version.
- `-m|--minified-esp-idf`: [Only applies if using `-s|--esp-idf-version`]. Deletes some idf folders to save space. Possible values [`YES, NO`]
- `-n|--nightly-version`: Nightly Rust toolchain version. Defaults to: `nightly`
- `-r|--rustup-home`: Path to .rustup. Defaults to: `~/.rustup`
- `-s|--esp-idf-version`: [ESP-IDF branch](https://github.com/espressif/esp-idf/branches) to install. When empty, no esp-idf is installed. Default: `""`
- `-t|--toolchain-version`: Xtensa Rust toolchain version
- `-x|--clear-cache`: Removes cached distribution files. Possible values: [`YES, NO`]

### Windows x64

Following instructions are specific for ESP32 and ESP32-S series based on Xtensa architecture.

Instructions for ESP-C series based on RISC-V architecture are described  in [RISC-V section](#riscv-installation).

#### Prerequisites

- Visual Studio - installed with option Desktop development with C++ - components: MSVCv142 - VS2019 C++ x86/64 build tools, Windows 10 SDK

![Visual Studio Installer - configuration](support/img/rust-windows-requirements.png?raw=true)

Installation of prerequisites with Chocolatey (run PowerShell as Administrator):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install cmake git ninja visualstudio2022-workload-vctools windows-sdk-10.0
```

#### Installation commands for PowerShell

```sh
git clone https://github.com/esp-rs/rust-build.git
cd rust-build
./Install-RustToolchain.ps1
```

Export variables are displayed at the end of the output from the script.

Installation of different version of toolchain:

```sh
./Install-RustToolchain.ps1 --toolchain-version 1.61.0.0 --export-file Export-EspRust.ps1
source ./Export-EspRust.ps1
```

## RISC-V Installation

Following instructions are specific for ESP32-C based on RISC-V architecture.

Install the RISC-V target for Rust:

```sh
rustup target add riscv32i-unknown-none-elf
```

## Building projects

### Cargo first approach

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
    - `riscv32imc-esp-espidf` for the ESP32-C3(RISC-V architecture).

    And `SERIAL` is the serial port connected to the target device.

    > [cargo-espflash](https://github.com/esp-rs/espflash/tree/master/cargo-espflash) also allows opening a serial monitor after flashing with `--monitor` option, see [Usage](https://github.com/esp-rs/espflash/tree/master/cargo-espflash#usage) section for more information about arguments.


### Idf first approach

When building for Xtensa targets, we need to [override the `esp` toolchain](https://rust-lang.github.io/rustup/overrides.html), there are several solutions:
      - Set `esp` toolchain as default: `rustup default esp`
      - Use `cargo +esp`
      - Override the project directory: `rustup override set esp`
      - Create a file called `rust-toolchain.toml` or `rust-toolchain` with:
        ```toml
        [toolchain]
        channel = "esp"
        ```
        
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

## Containers with Rust ESP environment

Alternatively, some container images, with pre-installed Rust and ESP-IDF, are published to Dockerhub and can be used to build Rust projects for ESP boards:

- [idf-rust](https://hub.docker.com/r/espressif/idf-rust)
 - Some tags contains only the toolchain. The naming convention for those tags is: `<xtensa-version>`
 - Some tags contains full environment with esp-idf installed, [wokwi-server](https://github.com/MabezDev/wokwi-server)
   and [web-flash](https://github.com/bjoernQ/esp-web-flash-server) to use them
   in Dev Containers. This tags are generated for `linux/arm64` and `linux/amd64`,
   and use the following naming convention: `<board>_<esp-idf>_<xtensa-version>`
- [idf-rust-examples](https://hub.docker.com/r/espressif/idf-rust-examples) - includes two examples: [rust-esp32-example](https://github.com/espressif/rust-esp32-example) and [rust-esp32-std-demo](https://github.com/ivmarkov/rust-esp32-std-demo).

Podman example with mapping multiple /dev/ttyUSB from host computer to the container:

```sh
podman run --device /dev/ttyUSB0 --device /dev/ttyUSB1 -it docker.io/espressif/idf-rust-examples
```

Docker (does not support flashing from container):

```sh
docker run -it espressif/idf-rust-examples
```

If you are using the `idf-rust-examples` image, instructions will be displayed on the screen.

## Dev Containers

Dev Container support is offered for VS Code, Gitpod and GitHub Codespaces,
resulting in a fully working environment to develop for ESP boards in Rust,
flash and simulate projects with Wokwi from the container.

Template projects [esp-template](https://github.com/esp-rs/esp-template/) and
[esp-idf-template](https://github.com/esp-rs/esp-template/) include a question for Dev Containers support.
