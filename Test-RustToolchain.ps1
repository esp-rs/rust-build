[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $ToolchainVersion = '1.56.0.1',
    [String]
    [ValidateSet("xtensa-esp32-espidf", "xtensa-esp32s2-espidf", "xtensa-esp32s3-espidf", "riscv32imc-esp-espidf")]
    $Target = "xtensa-esp32-espidf",
    [String]
    [ValidateSet("install", "reinstall", "uninstall", "skip")]
    $InstallationMode = 'reinstall',
    [String]
    [ValidateSet("build", "flash", "monitor")]
    $TestMode = "build",
    [String]
    $TestPort = "COM5"
)

$ErrorActionPreference = "Stop"
$RustStdDemo = "rust-esp32-std-demo"

"Processing configuration:"
"-Target           = ${Target}"
"-ToolchainVersion = ${ToolchainVersion}"
"-TestMode         = ${TestMode}"
"-TestPort         = ${TestPort}"

$ToolchainPrefix = "esp"
$ToolchainName = "${ToolchainPrefix}-${ToolchainVersion}"
$ExportFile="Export-Rust-${ToolchainName}.ps1"

if ("skip" -ne $InstallationMode) {
    ./Install-RustToolchain.ps1 `
        -ExportFile ${ExportFile} `
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

if ("build" -eq $TestMode) {
    cargo +${ToolchainName} build --target ${Target}
} elseif ("flash" -eq $TestMode) {
    "cargo +${ToolchainName} espflash --target ${Target} $TestPort"
    cargo +${ToolchainName} espflash --target ${Target} $TestPort
} elseif ("monitor" -eq $TestMode) {
    cargo +${ToolchainName} espflash --monitor --target ${Target} $TestPort
}
Pop-Location
