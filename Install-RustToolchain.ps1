[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $ExportFile = ''
)

$ErrorActionPreference = "Stop"
#Set-PSDebug -Trace 1

if (-Not (Get-Command 7z -errorAction SilentlyContinue)) {
    choco install 7zip
}

if ((rustup show | Select-String -Pattern nightly).Length -eq 0) {
    rustup toolchain install nightly
}

$Version="1.55.0-dev"
$Arch="x86_64-pc-windows-msvc"
$RustDist="rust-${Version}-${Arch}"
$ToolchainDestinationDir="${HOME}/.rustup/toolchains/esp"
$LlvmRelease="esp-12.0.1-20210823"
$IdfToolsPath="${HOME}/.espressif"
$IdfToolXtensaElfClang="${IdfToolsPath}/tools/xtensa-esp32-elf-clang/${LlvmRelease}-${Arch}"
$LlvmArch="win64"
$LlvmFile="xtensa-esp32-elf-llvm12_0_1-${LlvmRelease}-${LlvmArch}.zip"
$LlvmUrl="https://github.com/espressif/llvm-project/releases/download/${LlvmRelease}/${LlvmFile}"

if (Test-Path -Path ${ToolchainDestinationDir} -PathType Container) {
    "Previous installation of toolchain exist in: ${ToolchainDestinationDir}"
    "Please, remove the directory before new installation."
    exit 1
}

mkdir -p "${HOME}/.rustup/toolchains/" -ErrorAction SilentlyContinue
Push-Location "${HOME}/.rustup/toolchains"

if (-Not (Test-Path -Path "${RustDist}.zip" -PathType Leaf)) {
    Invoke-WebRequest "https://github.com/esp-rs/rust-build/releases/download/v${Version}/${RustDist}.zip" -OutFile "${RustDist}.zip"
}
7z x .\${RustDist}.zip
Pop-Location

rustup default esp

"* installing ${IdfToolXtensaElfClang}"
if (-Not (Test-Path -Path $IdfToolXtensaElfClang)) {
    if (-Not (Test-Path -Path ${LlvmFile} -PathType Leaf)) {
        "** downloading: ${LlvmUrl}"
        Invoke-WebRequest "https://github.com/espressif/llvm-project/releases/download/${LlvmRelease}/${LlvmFile}" -OutFile ${LlvmFile}
    }
    mkdir -p "${IdfToolsPath}/tools/xtensa-esp32-elf-clang/" -ErrorAction SilentlyContinue
    7z x ${LlvmFile}
    mv xtensa-esp32-elf-clang "${IdfToolXtensaElfClang}"
    "done"
} else {
    "already installed"
}

"Add following command to PowerShell profile"
$ExportContent='$env:PATH+=";' + "${IdfToolXtensaElfClang}/bin/" + '"'
$ExportContent+="`n" + '$env:LIBCLANG_PATH="' + "${IdfToolXtensaElfClang}/bin/libclang.dll" + '"'
$ExportContent

if ('' -ne $ExportFile) {
    Out-File -FilePath $ExportFile -InputObject $ExportContent
}
