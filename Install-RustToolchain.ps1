[CmdletBinding()]
param (
    [Parameter()]
    [String]
    [ValidateSet("x86_64-pc-windows-msvc", "x86_64-pc-windows-gnu")]
    $DefaultHost = "x86_64-pc-windows-msvc",
    [String]
    $ExportFile = 'Export-EspRust.ps1',
    [String]
    $ToolchainVersion = '1.66.0.0',
    [String]
    $ToolchainDestination = "${HOME}/.rustup/toolchains/esp",
    [String]
    $LlvmVersion = "esp-14.0.0-20220415",
    [String]
    [ValidateSet("install", "reinstall", "uninstall", "export")]
    $InstallationMode = 'install'
)

$ErrorActionPreference = "Stop"
# Disable progress bar when downloading - speed up download - https://stackoverflow.com/questions/28682642/powershell-why-is-using-invoke-webrequest-much-slower-than-a-browser-download
$ProgressPreference = 'SilentlyContinue'
$ExportContent = ""
#Set-PSDebug -Trace 1
$RustcMinimalMinorVersion="55"

"Processing configuration:"
"-DefaultHost          = ${DefaultHost}"
"-InstalltationMode    = ${InstallationMode}"
"-LlvmVersion          = ${LlvmVersion}"
"-ToolchainVersion     = ${ToolchainVersion}"
"-ToolchainDestination = ${ToolchainDestination}"

function InstallRust() {
    Invoke-WebRequest https://win.rustup.rs/x86_64 -OutFile rustup-init.exe
    ./rustup-init.exe --default-host ${DefaultHost} --default-toolchain stable -y
    $env:PATH+=";$env:USERPROFILE\.cargo\bin"
    $ExportContent+="`n" + '$env:PATH+=";$env:USERPROFILE\.cargo\bin"'
}

function InstallRustFmt() {
    rustup component add rustfmt --toolchain=stable
}

function ExportVariables() {
    "Add following command to PowerShell profile"
    $ExportContent+="`n" + '$env:PATH="' + "${IdfToolXtensaElfClang}/bin/;" + '$env:PATH"'
    $ExportContent+="`n" + '$env:LIBCLANG_PATH="' + "${IdfToolXtensaElfClang}/bin/libclang.dll" + '"'
    # Workaround of https://github.com/espressif/esp-idf/issues/7910
    $ExportContent+="`n" + '$env:PIP_USER="no"'
    $ExportContent

    if ('' -ne $ExportFile) {
        Out-File -FilePath $ExportFile -InputObject $ExportContent
    }
}

if (-Not (Get-Command rustup -ErrorAction SilentlyContinue)) {
    InstallRust
}

if ((rustup show | Select-String -Pattern stable).Length -eq 0) {
    InstallRust
}

if ((rustc --version).Substring(8,2) -lt $RustcMinimalMinorVersion) {
    "rustc version is too low, requires 1.${RustcMinimalMinorVersion}"
    "calling rustup"
    InstallRust
}

# It seems there is a dependency on nightly for some reason only on Windows
# It might be caused by way of packaging to dist ZIP.
if ((rustup show | Select-String -Pattern nightly).Length -eq 0) {
    rustup toolchain install nightly
}

if (-Not (Get-Command rustfmt -errorAction SilentlyContinue)) {
    InstallRustFmt
}

if ((rustfmt --version | Select-String -Pattern stable).Length -eq 0) {
    InstallRustFmt
}

$Arch="x86_64-pc-windows-msvc"
$EspFlashUrl="https://github.com/esp-rs/espflash/releases/latest/download/cargo-espflash-${Arch}.zip"
$CargoBin="${env:USERPROFILE}\.cargo\bin"
$EspFlashBin="${CargoBin}\cargo-espflash.exe"
$RustDist="rust-${ToolchainVersion}-${DefaultHost}"
$RustDistZipUrl="https://github.com/esp-rs/rust-build/releases/download/v${ToolchainVersion}/${RustDist}.zip"
$IdfToolsPath="${HOME}/.espressif"
$IdfToolXtensaElfClang="${IdfToolsPath}/tools/xtensa-esp32-elf-clang/${LlvmVersion}-${Arch}"
$LlvmArch="x86_64-pc-windows-msvc"
$LlvmArtifactVersion=$LlvmVersion.Substring(4).Substring(0,6).Replace(".","_")
$LlvmFile="xtensa-esp32-elf-llvm${LlvmArtifactVersion}-${LlvmVersion}-${LlvmArch}.zip"
#$LlvmUrl="https://github.com/espressif/llvm-project/releases/download/${LlvmVersion}/${LlvmFile}"
$LlvmUrl="https://github.com/esp-rs/rust-build/releases/download/llvm-project-14.0-minified/${LlvmFile}"

# Only export variables
if ("export" -eq $InstallationMode) {
    ExportVariables
    Exit 0
}

if (("uninstall" -eq $InstallationMode) -or ("reinstall" -eq $InstallationMode)) {
    "Removing:"

    " - ${ToolchainDestination}"
    Remove-Item -Recurse -Force -Path ${ToolchainDestination} -ErrorAction SilentlyContinue

    " - ${IdfToolXtensaElfClang}"
    Remove-Item -Recurse -Force -Path ${IdfToolXtensaElfClang} -ErrorAction SilentlyContinue

    if ("uninstall" -eq $InstallationMode) {
        exit 0
    }
}

if (Test-Path -Path ${ToolchainDestination} -PathType Container) {
    "Previous installation of toolchain exist in: ${ToolchainDestination}"
    "Please, remove the directory before new installation."
    exit 1
}

mkdir -p "${HOME}/.rustup/toolchains/" -ErrorAction SilentlyContinue
Push-Location "${HOME}/.rustup/toolchains"

"* installing esp toolchain"
if (-Not (Test-Path -Path "${RustDist}.zip" -PathType Leaf)) {
    "** downloading: ${RustDistZipUrl}"
    Invoke-WebRequest "${RustDistZipUrl}" -OutFile "${RustDist}.zip"
}

Expand-Archive .\${RustDist}.zip -DestinationPath ${ToolchainDestination}-tmp
mv ${ToolchainDestination}-tmp/* ${ToolchainDestination}
Remove-Item -Recurse -Force ${ToolchainDestination}-tmp
"Toolchains:"
rustup toolchain list
Pop-Location

"* installing ${IdfToolXtensaElfClang}"
if (-Not (Test-Path -Path $IdfToolXtensaElfClang)) {
    if (-Not (Test-Path -Path ${LlvmFile} -PathType Leaf)) {
        "** downloading: ${LlvmUrl}"
        Invoke-WebRequest "${LlvmUrl}" -OutFile ${LlvmFile}
    }
    mkdir -p "${IdfToolsPath}/tools/xtensa-esp32-elf-clang/" -ErrorAction SilentlyContinue
    Expand-Archive ${LlvmFile} -DestinationPath ${IdfToolXtensaElfClang}-tmp
    mv ${IdfToolXtensaElfClang}-tmp/xtensa-esp32-elf-clang "${IdfToolXtensaElfClang}"
    Remove-Item -Recurse -Force ${IdfToolXtensaElfClang}-tmp/
    "done"
} else {
    "already installed"
}

"Install common dependencies"
cargo install ldproxy

# Install espflash from binary archive
if (-Not (Test-Path $EspFlashBin -PathType Leaf)) {
    "** installing cargo-espflash from $EspFlashUrl to $EspFlashBin"
    Invoke-WebRequest $EspFlashUrl -OutFile "${EspFlashBin}.zip"
    Expand-Archive "${EspFlashBin}.zip" -DestinationPath $CargoBin
    Remove-Item -Path "${EspFlashBin}.zip"
}

ExportVariables
