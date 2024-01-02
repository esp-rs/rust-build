# rust-build

This repository contains:

- Workflows for building a Rust fork [esp-rs/rust](https://github.com/esp-rs/rust) with Xtensa support
- Binary artifacts in [Releases](https://github.com/esp-rs/rust-build/releases)
- An [installation script](install-rust-toolchain.sh) to locally install a pre-compiled nightly ESP32 toolchain

If you want to know more about the Rust ecosystem on ESP targets, see [The Rust on ESP Book chapter](https://esp-rs.github.io/book/installation/index.html)

## Table of Contents

- [rust-build](#rust-build)
  - [Table of Contents](#table-of-contents)
  - [Xtensa Installation](#xtensa-installation)
  - [`espup` installation](#espup-installation)
      - [Download installer in Bash](#download-installer-in-bash)
    - [Linux and macOS](#linux-and-macos)
      - [Prerequisites](#prerequisites)
      - [Installation commands](#installation-commands)
      - [Set up the environment variables](#set-up-the-environment-variables)
      - [Arguments](#arguments)
      - [Windows Long path limitation](#windows-long-path-limitation)
    - [Windows x86\_64 MSVC](#windows-x86_64-msvc)
      - [Prerequisites x86\_64 MSVC](#prerequisites-x86_64-msvc)
    - [Windows x86\_64 GNU](#windows-x86_64-gnu)
      - [Prerequisites x86\_64 GNU](#prerequisites-x86_64-gnu)
      - [Long path limitation](#long-path-limitation)
  - [RISC-V Installation](#risc-v-installation)
  - [Building projects](#building-projects)
    - [Cargo first approach](#cargo-first-approach)
    - [Idf first approach](#idf-first-approach)
  - [Using Containers](#using-containers)
  - [Using Dev Containers](#using-dev-containers)

## Xtensa Installation

Deployment is done using [`espup`](https://github.com/esp-rs/espup#installation)
## `espup` installation
```sh
cargo install espup
espup install # To install Espressif Rust ecosystem
# [Unix]: Source the following file in every terminal before building a project
. $HOME/export-esp.sh
```
Or, downloading the pre-compiled release binaries:
- Linux aarch64
  ```sh
  curl -L https://github.com/esp-rs/espup/releases/latest/download/espup-aarch64-unknown-linux-gnu -o espup
  chmod a+x espup
  ./espup install
  # Source the following file in every terminal before building a project
  . $HOME/export-esp.sh
  ```
- Linux x86_64
  ```sh
  curl -L https://github.com/esp-rs/espup/releases/latest/download/espup-x86_64-unknown-linux-gnu -o espup
  chmod a+x espup
  ./espup install
  # Source the following file in every terminal before building a project
  . $HOME/export-esp.sh
  ```
- macOS aarch64
  ```sh
  curl -L https://github.com/esp-rs/espup/releases/latest/download/espup-aarch64-apple-darwin -o espup
  chmod a+x espup
  ./espup install
  # Source the following file in every terminal before building a project
  . $HOME/export-esp.sh
  ```
- macOS x86_64
  ```sh
  curl -L https://github.com/esp-rs/espup/releases/latest/download/espup-x86_64-apple-darwin -o espup
  chmod a+x espup
  ./espup install
  # Source the following file in every terminal before building a project
  . $HOME/export-esp.sh
  ```
- Windows MSVC
  ```powershell
  Invoke-WebRequest 'https://github.com/esp-rs/espup/releases/latest/download/espup-x86_64-pc-windows-msvc.exe' -OutFile .\espup.exe
  .\espup.exe install
  ```
- Windows GNU
  ```powershell
  Invoke-WebRequest 'https://github.com/esp-rs/espup/releases/latest/download/espup-x86_64-pc-windows-msvc.exe' -OutFile .\espup.exe
  .\espup.exe install
  ```

> For Windows MSVC/GNU, Rust environment can also be installed with Universal Online idf-installer: https://dl.espressif.com/dl/esp-idf/


#### Download installer in Bash

**Deprecated method**

```bash
curl -LO https://github.com/esp-rs/rust-build/releases/download/v1.75.0.0/install-rust-toolchain.sh
chmod a+x install-rust-toolchain.sh
```

### Linux and macOS

The following instructions are specific for the ESP32 and ESP32-S series based on Xtensa architecture.

Instructions for ESP-C series based on RISC-V architecture are described in [RISC-V section](#risc-v-installation).

#### Prerequisites

- Linux:
  - [Dependencies (command for Ubuntu/Debian)](https://github.com/esp-rs/esp-idf-template/blob/master/cargo/.devcontainer/Dockerfile#L16):
    ```sh
    apt-get install -y git curl gcc clang ninja-build cmake libudev-dev unzip xz-utils \
    python3 python3-pip python3-venv libusb-1.0-0 libssl-dev pkg-config libpython2.7
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
./install-rust-toolchain.sh --toolchain-version 1.75.0.0
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
- `-b|--build-target`: Comma separated list of targets \[`esp32,esp32s2,esp32s3,esp32c3,all`]. Defaults to: `esp32,esp32s2,esp32s3`
- `-c|--cargo-home`: Cargo path.
- `-d|--toolchain-destination`: Toolchain installation folder. Defaults to: `<rustup_home>/toolchains/esp`
- `-e|--extra-crates`: Extra crates to install. Defaults to: `ldproxy cargo-espflash`
- `-f|--export-file`: Destination of the export file generated. Defaults to: `export-esp.sh`
- `-i|--installation-mode`: Installation mode: \[`install, reinstall, uninstall`]. Defaults to: `install`
- `-k|--minified-llvm`: Use minified LLVM. Possible values: \[`YES, NO`]. Defaults to: `YES`
- `-l|--llvm-version`: LLVM version.
- `-m|--minified-esp-idf`: \[Only applies if using `-s|--esp-idf-version`]. Deletes some idf folders to save space. Possible values \[`YES, NO`]. Defaults to: `NO`
- `-n|--nightly-version`: Nightly Rust toolchain version. Defaults to: `nightly`
- `-r|--rustup-home`: Path to .rustup. Defaults to: `~/.rustup`
- `-s|--esp-idf-version`: [ESP-IDF branch](https://github.com/espressif/esp-idf/branches) to install. When empty, no esp-idf is installed. Default: `""`
- `-t|--toolchain-version`: Xtensa Rust toolchain version
- `-x|--clear-cache`: Removes cached distribution files. Possible values: \[`YES, NO`]. Defaults to: `YES`

#### Windows Long path limitation

Several build tools have problem with long paths on Windows including Git and CMake. We recommend to put project on short path or use command `subst` to map the directory with the project to separate disk letter.

```
subst "R:" "rust-project"
```

### Windows x86_64 MSVC

The following instructions are specific for the ESP32 and ESP32-S series based on Xtensa architecture. If you do not have Visual Studio and Windows 10 SDK installed, consider the alternative option [Windows x86_64 GNU](#windows-x86_64-gnu).

Instructions for ESP-C series based on RISC-V architecture are described  in [RISC-V section](#risc-v-installation).

#### Prerequisites x86_64 MSVC

Installation of prerequisites using [Winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/):

```powershell
winget install --id Git.Git
winget install Python # requirements for ESP-IDF based development, skip in case of Bare metal
winget install -e --id Microsoft.WindowsSDK
winget install Microsoft.VisualStudio.2022.BuildTools --silent --override "--wait --quiet --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64"
```

Installation of prerequisites using Visual Studio installer GUI - installed with option Desktop development with C++ - components: MSVCv142 - VS2019 C++ x86/64 build tools, Windows 11 SDK

![Visual Studio Installer - configuration](support/img/rust-windows-requirements.png?raw=true)

Installation of MSVC and Windows 11 SDK using [vs_buildtools.exe](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022):

```powershell
Invoke-WebRequest 'https://aka.ms/vs/17/release/vs_buildtools.exe' -OutFile .\vs_buildtools.exe
.\vs_BuildTools.exe --passive --wait --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.20348
```

Installation of prerequisites using Chocolatey (run PowerShell as Administrator):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install visualstudio2022-workload-vctools windows-sdk-10.0 -y
choco install cmake git ninja python3 -y  # requirements for ESP-IDF based development, skip in case of Bare metal
```

Main installation:

```powershell
Invoke-WebRequest 'https://github.com/esp-rs/espup/releases/latest/download/espup-x86_64-pc-windows-msvc.exe' -OutFile .\espup.exe
.\espup.exe install
```

### Windows x86_64 GNU

The following instructions describe deployment with the GNU toolchain. If you're using Visual Studio with Windows 10 SDK, consider option [Windows x86_64 MSVC](#windows-x86_64-msvc).

#### Prerequisites x86_64 GNU

Install MinGW x86_64 e.g., from releases https://github.com/niXman/mingw-builds-binaries/releases and add bin to environment variable PATH

```powershell
choco install 7zip -y
Invoke-WebRequest https://github.com/niXman/mingw-builds-binaries/releases/download/12.1.0-rt_v10-rev3/x86_64-12.1.0-release-posix-seh-rt_v10-rev3.7z -OutFile x86_64-12.1.0-release-posix-seh-rt_v10-rev3.7z
7z x x86_64-12.1.0-release-posix-seh-rt_v10-rev3.7z
$env:PATH+=";.....\x86_64-12.1.0-release-posix-seh-rt_v10-rev3\mingw64\bin"
```

Main installation:

```powershell
Invoke-WebRequest 'https://github.com/esp-rs/espup/releases/latest/download/espup-x86_64-pc-windows-msvc.exe' -OutFile .\espup.exe
.\espup.exe install
```

#### Long path limitation

Several build tools have problem with long paths on Windows including Git and CMake. We recommend to put project on short path or use command `subst` to map the directory with the project to separate disk letter.

```
subst "R:" "rust-project"
```

## RISC-V Installation

The following instructions are specific for ESP32-C based on RISC-V architecture.

Install the RISC-V target for Rust:

```sh
rustup target add riscv32imc-unknown-none-elf
```

## Building projects

### Cargo first approach

1. Install `cargo-generate`

    ```sh
    cargo install cargo-generate
    ```
2. Generate project from template with one of the following templates

    ```sh
    # STD Project
    cargo generate esp-rs/esp-idf-template cargo
    # NO-STD (Bare-metal) Project
    cargo generate esp-rs/esp-template
    ```

  To understand the differences between the two ecosystems, see [Ecosystem Overview chapter of the book](https://esp-rs.github.io/book/overview/index.html). There is also a Chapter that explains boths template projects:
  * [`std` template explanation](https://esp-rs.github.io/book/writing-your-own-application/generate-project/esp-idf-template.html)
  * [`no_std` template explanation](https://esp-rs.github.io/book/writing-your-own-application/no-std-applications/understanding-esp-template.html)

3. Build and flash:

    ```sh
    cargo espflash flash <SERIAL>
    ```

    Where  `SERIAL` is the serial port connected to the target device.

    > [cargo-espflash](https://github.com/esp-rs/espflash/tree/master/cargo-espflash) also allows opening a serial monitor after flashing with `--monitor` option.
    >
    > If no `SERIAL` argument is used, `cargo-espflash` will print a list of the connected devices, so the user can choose
    > which one to flash.
    >
    > See [Usage](https://github.com/esp-rs/espflash/tree/master/cargo-espflash#usage) section for more information about arguments.

    > If `espflash` is installed (`cargo install espflash`), `cargo run` will build, flash the device, and open a serial monitor.

If you are looking for inspiration or more complext projects see:
- [Awesome ESP Rust - Projects Section](https://github.com/esp-rs/awesome-esp-rust#projects)
- [Rust on ESP32 STD demo app](https://github.com/ivmarkov/rust-esp32-std-demo)
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

    - `esp32` for the ESP32(Xtensa architecture). \[Default]
    - `esp32s2` for the ESP32-S2(Xtensa architecture).
    - `esp32s3` for the ESP32-S3(Xtensa architecture).

3. Build and flash

    ```sh
    idf.py build flash
    ```

## Using Containers

Alternatively, some container images with pre-installed Rust and ESP-IDF, are published to Dockerhub and can be used to build Rust projects for ESP boards:

- [idf-rust](https://hub.docker.com/r/espressif/idf-rust)
 - Tags contain the required toolchain. The naming convention for those tags is: `<board>_<xtensa-version>`
 - Tags contain [wokwi-server](https://github.com/MabezDev/wokwi-server)
   and [web-flash](https://github.com/bjoernQ/esp-web-flash-server) installed to use them
   in Dev Containers.
 - Tags are generated for `linux/arm64` and `linux/amd64`,
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

## Using Dev Containers

Dev Container support is offered for VS Code, Gitpod, and GitHub Codespaces,
resulting in a fully working environment to develop for ESP boards in Rust,
flash and simulate projects with Wokwi from the container.

Template projects [esp-template](https://github.com/esp-rs/esp-template/) and
[esp-idf-template](https://github.com/esp-rs/esp-idf-template/) include a question for Dev Containers support.

## Release process

Before beginning preparation for a new release create branch `build/X.Y.Z.W` where `X.Y.Z` matches Rust release number and `W` is build number assigned by esp-rs. `W` has a tendency to be in the range 0-2 during one release.

On the branch change all version numbers from the previous release to the new one using replace function (e.g. in VS Code). Examples of replace: `1.63.0.1 -> 1.64.0.0`. Commit files including CI files to the branch.

### Building release

All build operations must be performed on custom runners, because of large storage required by the build process. Check Settings that all runners are online.

Perform custom dispatch. Change branch to `build/X.Y.Z.W`, change *Branch of rust-build to us* to `build/X.Y.Z.W`:

* [aarch64-unknown-linux-gnu](https://github.com/esp-rs/rust-build/actions/workflows/build-rust-aarch64-unknown-linux-gnu-self-hosted-dispatch.yaml)
* [aarch64-apple-darwin](https://github.com/esp-rs/rust-build/actions/workflows/build-rust-aarch64-apple-darwin-self-hosted-dispatch.yaml)
* [x86_64-apple-darwin](https://github.com/esp-rs/rust-build/actions/workflows/build-rust-x86_64-apple-darwin-self-hosted-dispatch.yaml)
* [x86_64-pc-windows-gnu](https://github.com/esp-rs/rust-build/actions/workflows/build-rust-x86_64-pc-windows-gnu-self-hosted-dispatch.yaml)
* [x86_64-pc-windows-msvc](https://github.com/esp-rs/rust-build/actions/workflows/build-rust-x86_64-pc-windows-msvc-self-hosted-dispatch.yaml)
* [x86_64-unknown-linux-gnu](https://github.com/esp-rs/rust-build/actions/workflows/build-rust-x86_64-unknown-linux-gnu-self-hosted-dispatch.yaml)
* [src](https://github.com/esp-rs/rust-build/actions/workflows/build-rust-src-dispatch.yaml)

Once all things are in place, also upload the installer to releases:

* [installer workflow](https://github.com/esp-rs/rust-build/actions/workflows/release-installer-dispatch.yaml)

Perform test jobs.

Send notification to Matrix channel about the pre-release.

### Finalization of release (about 2-3 days later)

Edit Release, turn off Pre-release flag, and Save

Send notification to Matrix channel about the pre-release.

### Rollback release

Rollback of the release is possible when a significant bug occurs that damages the release for all platforms.

First rule: Do not panic. :-) Just mark the release as Pre-release in GitHub releases.

If `build/X.Y.Z.W` branch was already merged to main, change the default version in main to `build/a.b.c.d` where `a.b.c.d` corresponds to previously known working release. E.g. from `build/1.63.0.1` to `build/1.63.0.0`.

### Uploading new image tags to [espressif/idf-rust](https://hub.docker.com/r/espressif/idf-rust)

Once the release is ready, [manually run the `Publish IDF-Rust Tags` workflow](https://github.com/esp-rs/rust-build/actions/workflows/publish-idf-rust-tags.yml) with:
- `Branch of rust-build to use` pointing to `main` if the `build/X.Y.Z.W` branch was already merged to `main`, or pointing to `build/X.Y.Z.W` if has not been merged yet, but the branch is ready and feature complete.
- `Version of Rust toolchain` should be `X.Y.Z.W`.
