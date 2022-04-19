[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $ToolchainVersion = '1.60.0.1',
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

if ("build" -eq $TestMode) {
    cargo +${ToolchainName} build --target ${Target} --features "${Features}"
} elseif ("flash" -eq $TestMode) {
    "cargo +${ToolchainName} espflash --features '${Features}' --target ${Target} $TestPort "
    cargo +${ToolchainName} espflash --features "${Features}" --target ${Target} $TestPort
} elseif ("monitor" -eq $TestMode) {
    cargo +${ToolchainName} espflash --monitor --features "${Features}" --target ${Target} $TestPort
}
Pop-Location
