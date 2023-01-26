[CmdletBinding()]
param (
    [Parameter()]
    [String]
    [ValidateSet("x86_64-pc-windows-msvc", "x86_64-pc-windows-gnu")]
    $DefaultHost = "x86_64-pc-windows-msvc",
    [String]
    $ToolchainVersion = '1.67.0.0',
    [String]
    [ValidateSet("xtensa-esp32-espidf", "xtensa-esp32s2-espidf", "xtensa-esp32s3-espidf", "riscv32imc-esp-espidf")]
    $Target = "xtensa-esp32-espidf",
    [String]
    [ValidateSet("install", "reinstall", "uninstall", "skip")]
    $InstallationMode = 'reinstall',
    [String]
    $LlvmVersion = "esp-14.0.0-20220415",
    [String]
    [ValidateSet("build", "flash", "monitor")]
    $TestMode = "build",
    [String]
    $TestPort = "COM5",
    [string]
    $Features = "" # space separated list of features
)

$ErrorActionPreference = "Stop"
$RustStdDemo = "rust-esp32-std-demo"

"Processing configuration:"
"-DefaultHost      = ${DefaultHost}"
"-Features         = ${Features}"
"-LlvmVersion      = ${LlvmVersion}"
"-Target           = ${Target}"
"-ToolchainVersion = ${ToolchainVersion}"
"-TestMode         = ${TestMode}"
"-TestPort         = ${TestPort}"

$ToolchainPrefix = "esp"
$ToolchainName = "${ToolchainPrefix}-${ToolchainVersion}"
$ExportFile="Export-Rust-${ToolchainName}.ps1"

if ("skip" -ne $InstallationMode) {
    ./Install-RustToolchain.ps1 `
        -DefaultHost ${DefaultHost} `
        -ExportFile ${ExportFile} `
        -LlvmVersion ${LlvmVersion} `
        -InstallationMode ${InstallationMode} `
        -ToolchainVersion ${ToolchainVersion} `
        -ToolchainDestination "${HOME}/.rustup/toolchains/${ToolchainName}"
}

. ./${ExportFile}

if (-Not (Test-Path -Path ${RustStdDemo} -PathType Container)) {
    git clone https://github.com/ivmarkov/${RustStdDemo}.git
}

Push-Location ${RustStdDemo}
$env:RUST_ESP32_STD_DEMO_WIFI_SSID="rust"
$env:RUST_ESP32_STD_DEMO_WIFI_PASS="for-esp32"

$CargoParameters = @("+${ToolchainName}")

if ("build" -eq $TestMode) {
    $CargoParameters += 'build'
} elseif ("flash" -eq $TestMode) {
    $CargoParameters += "espflash"
} elseif ("monitor" -eq $TestMode) {
    $CargoParameters += "espflash"
    $CargoParameters += "--monitor"
}

$CargoParameters += "--target"
$CargoParameters += "${Target}"

if ("" -ne $Features) {
    $CargoParameters += "--features"
    $CargoParameters += "${Features}"
}

if (("flash" -eq $TestMode) -or ("monitor" -eq $TestMode)) {
  $CargoParameters += "${TestPort}"
}

"cargo $CargoParameters"
cargo $CargoParameters

Pop-Location
