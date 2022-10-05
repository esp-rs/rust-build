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
    - [Windows x64 GNU](#windows-x86_64-gnu)
      - [Prerequisites](#prerequisites-x86_64-gnu)
      - [Installation commands for PowerShell](#installation-commands-for-powershell)
    - [Windows x64 MSVC](#windows-x86_64-msvc)
      - [Prerequisites](#prerequisites-x86_64-msvc)
      - [Installation commands for PowerShell](#installation-commands-for-powershell-1)
  - [RISC-V Installation](#riscv-installation)
  - [Building projects](#building-projects)
    - [Cargo first approach](#cargo-first-approach)
    - [Idf first approach](#idf-first-approach)
  - [Podman/Docker Rust ESP environment](#podmandocker-rust-esp-environment)
  - [Dev-Containers](#dev-containers)

## Xtensa Installation

Download the installer from the [Release section](https://github.com/esp-rs/rust-build/releases).

### Download installer

#### Download installer in Bash

```bash
curl -LO https://github.com/esp-rs/rust-build/releases/download/v1.64.0.0/install-rust-toolchain.sh
chmod a+x install-rust-toolchain.sh
```

#### Download installer in PowerShell

```powershell
Invoke-WebRequest 'https://github.com/esp-rs/rust-build/releases/download/v1.64.0.0/Install-RustToolchain.ps1' -OutFile .\Install-RustToolchain.ps1
```

### Linux and macOS

The following instructions are specific for the ESP32 and ESP32-S series based on Xtensa architecture.

Instructions for ESP-C series based on RISC-V architecture are described in [RISC-V section](#riscv-installation).

#### Prerequisites

- Linux:
  - [Dependencies (command for Ubuntu/Debian)](https://github.com/esp-rs/esp-idf-template/blob/master/cargo/.devcontainer/Dockerfile#L16):
    ```sh
    apt-get install -y git curl gcc clang ninja-build cmake libudev-dev unzip xz-utils \
    python3 python3-pip python3-venv libusb-1.0-0 libssl-dev pkg-config libtinfo5 libpython2.7
    ```

No prerequisites are needed for macOS.

#### Installation commands

```sh
git clone https://github.com/esp-rs/rust-build.git
cd rust-build
./install-rust-toolchain.sh
. ./export-esp.sh
```

Run `./install-rust-toolchain.sh --help` for more information about arguments.

Installation of different version of the toolchain:

```
./install-rust-toolchain.sh --toolchain-version 1.64.0.0
. ./export-esp.sh
```

#### Set up the environment variables
We need to update environment variables as some of the installed tools are not
yet added to the PATH environment variable, we also need to add LIBCLANG_PATH
environment variable to avoid conflicts with the system Clang. The environment
variables that we need to update are shown at the end of the install script and
stored in an export file. By default this export file is `export-esp.sh` but can
be modified with the `-f|--export-file` argument.

We must set the environment variables in every terminal session.


> **Note**
> If the export variables are added to the shell startup script, the shell may need to be refreshed.

#### Arguments
- `-b|--build-target`: Comma separated list of targets [`esp32,esp32s2,esp32s3,esp32c3,all`]. Defaults to: `esp32,esp32s2,esp32s3`
- `-c|--cargo-home`: Cargo path.
- `-d|--toolchain-destination`: Toolchain installation folder. Defaults to: `<rustup_home>/toolchains/esp`
- `-e|--extra-crates`: Extra crates to install. Defaults to: `ldproxy cargo-espflash`
- `-f|--export-file`: Destination of the export file generated. Defaults to: `export-esp.sh`
- `-i|--installation-mode`: Installation mode: [`install, reinstall, uninstall`]. Defaults to: `install`
- `-k|--minified-llvm`: Use minified LLVM. Possible values: [`YES, NO`]. Defaults to: `YES`
- `-l|--llvm-version`: LLVM version.
- `-m|--minified-esp-idf`: [Only applies if using `-s|--esp-idf-version`]. Deletes some idf folders to save space. Possible values [`YES, NO`]. Defaults to: `NO`
- `-n|--nightly-version`: Nightly Rust toolchain version. Defaults to: `nightly`
- `-r|--rustup-home`: Path to .rustup. Defaults to: `~/.rustup`
- `-s|--esp-idf-version`: [ESP-IDF branch](https://github.com/espressif/esp-idf/branches) to install. When empty, no esp-idf is installed. Default: `""`
- `-t|--toolchain-version`: Xtensa Rust toolchain version
- `-x|--clear-cache`: Removes cached distribution files. Possible values: [`YES, NO`]. Defaults to: `YES`

### Windows x86_64 GNU

The following instructions describe deployment with the GNU toolchain. If you're using Visual Studio with Windows 10 SDK, consider option [Windows x86_64 MSVC](#windows-x86_64-msvc).

#### Prerequisites x86_64 GNU

Install MinGW x86_64 e.g., from releases https://github.com/niXman/mingw-builds-binaries/releases and add bin to environment variable PATH

```powershell
choco install 7zip -y
Invoke-WebRequest https://github.com/niXman/mingw-builds-binaries/releases/download/12.1.0-rt_v10-rev3/x86_64-12.1.0-release-posix-seh-rt_v10-rev3.7z -OutFile x86_64-12.1.0-release-posix-seh-rt_v10-rev3.7z
7z e x86_64-12.1.0-release-posix-seh-rt_v10-rev3.7z
$env:PATH+=";.....\x86_64-12.1.0-release-posix-seh-rt_v10-rev3\mingw64\bin"
```

Install ESP-IDF using Windows installer https://dl.espressif.com/dl/esp-idf/
#### Installation commands for PowerShell

Activate ESP-IDF PowerShell and enter following command:

```powershell
git clone https://github.com/esp-rs/rust-build.git
cd rust-build
./Install-RustToolchain.ps1 -DefaultHost x86_64-pc-windows-gnu -ExportFile Export-EspRust.ps1
. ./Export-EspRust.ps1
```

### Windows x86_64 MSVC

The following instructions are specific for the ESP32 and ESP32-S series based on Xtensa architecture. If you do not have Visual Studio and Windows 10 SDK installed, consider the alternative option [Windows x86_64 GNU](#windows-x86_64-gnu).

Instructions for ESP-C series based on RISC-V architecture are described  in [RISC-V section](#riscv-installation).

#### Prerequisites x86_64 MSVC

- Visual Studio - installed with option Desktop development with C++ - components: MSVCv142 - VS2019 C++ x86/64 build tools, Windows 10 SDK

![Visual Studio Installer - configuration](support/img/rust-windows-requirements.png?raw=true)

Installation of prerequisites with Chocolatey (run PowerShell as Administrator):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install cmake git ninja visualstudio2022-workload-vctools windows-sdk-10.0 -y
```

#### Installation commands for PowerShell

```sh
git clone https://github.com/esp-rs/rust-build.git
cd rust-build
./Install-RustToolchain.ps1
```

Export variables are displayed at the end of the output from the script.

Installation of different versions of toolchain:

```sh
./Install-RustToolchain.ps1 -ToolchainVersion 1.64.0.0
. ./Export-EspRust.ps1
```

#### Set up the environment variables
We need to update environment variables as some of the installed tools are not
yet added to the PATH environment variable, we also need to add LIBCLANG_PATH
environment variable to avoid conflicts with the system Clang. The environment
variables that we need to update are stored in an export file. By default this
export file is `Export-EspRust.ps1` but can be modified with the `-ExportFile` argument.

We must set the environment variables in every terminal session.


> **Note**
> If the export variables are added to the shell startup script, the shell may need to be refreshed.

## RISC-V Installation

The following instructions are specific for ESP32-C based on RISC-V architecture.

Install the RISC-V target for Rust:

```sh
rustup target add riscv32imc-unknown-none-elf
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

Alternatively, some container images with pre-installed Rust and ESP-IDF, are published to Dockerhub and can be used to build Rust projects for ESP boards:

- [idf-rust](https://hub.docker.com/r/espressif/idf-rust)
 - Some tags contain only the toolchain. The naming convention for those tags is: `<xtensa-version>`
 - Some tags contain full environment with esp-idf installed, [wokwi-server](https://github.com/MabezDev/wokwi-server)
   and [web-flash](https://github.com/bjoernQ/esp-web-flash-server) to use them
   in Dev Containers. This tags are generated for `linux/arm64` and `linux/amd64`,
   and use the following naming convention: `<board>_<esp-idf>_<xtensa-version>`
- [idf-rust-examples](https://hub.docker.com/r/espressif/idf-rust-examples) - includes two examples: [rust-esp32-example](https://github.com/espressif/rust-esp32-example) and [rust-esp32-std-demo](https://github.com/ivmarkov/rust-esp32-std-demo).

Podman example with mapping multiple /dev/ttyUSB from host computer to the container:

```sh
podman run --device /dev/ttyUSB0 --device /dev/ttyUSB1 -it docker.io/espressif/idf-rust-examples
```

Docker (does not support flashing from a container):

```sh
docker run -it espressif/idf-rust-examples
```

If you are using the `idf-rust-examples` image, instructions will be displayed on the screen.

## Dev Containers

Dev Container support is offered for VS Code, Gitpod, and GitHub Codespaces,
resulting in a fully working environment to develop for ESP boards in Rust,
flash and simulate projects with Wokwi from the container.

Template projects [esp-template](https://github.com/esp-rs/esp-template/) and
[esp-idf-template](https://github.com/esp-rs/esp-idf-template/) include a question for Dev Containers support.
