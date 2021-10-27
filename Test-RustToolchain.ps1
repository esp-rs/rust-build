[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $ToolchainVersion = '1.56.0.1',
    [String]
    $BuildTarget = "xtensa-esp32-espidf",
    [String]
    $InstallationMode = 'reinstall' # install, reinstall, uninstall
)

$ErrorActionPreference = "Stop"
$RustStdDemo = "rust-esp32-std-demo"

"Processing configuration:"
"-BuildTarget      = ${BuildTarget}"
"-ToolchainVersion = ${ToolchainVersion}"

$ToolchainPrefix = "esp"
$ToolchainName = "${ToolchainPrefix}-${ToolchainVersion}"
$ExportFile="Export-Rust-${ToolchainName}.ps1"

./Install-RustToolchain.ps1 `
    -ExportFile ${ExportFile} `
    -InstallationMode ${InstallationMode} `
    -ToolchainVersion ${ToolchainVersion} `
    -ToolchainDestination "${HOME}/.rustup/toolchains/${ToolchainName}"

. ./${ExportFile}

if (-Not (Test-Path -Path ${RustStdDemo} -PathType Container)) {
    git clone https://github.com/ivmarkov/${RustStdDemo}.git
}

Push-Location ${RustStdDemo}
$env:RUST_ESP32_STD_DEMO_WIFI_SSID="rust"
$env:RUST_ESP32_STD_DEMO_WIFI_PASS="for-esp32"

cargo +${ToolchainName} build --target ${BuildTarget}
Pop-Location
