[CmdletBinding()]
param (
    [Parameter()]
    [String]
    [ValidateSet("x86_64-pc-windows-msvc", "x86_64-pc-windows-gnu")]
    $DefaultHost = "x86_64-pc-windows-msvc"
)
# Helper script to perform repackaging of Windows release

# Stop on error
$ErrorActionPreference = "Stop"

$RustVersion="nightly"
$ReleaseVersion="1.63.0.1"

if (Test-Path -Path esp -PathType Container) {
    Remove-Item -Recurse -Force -Path esp
    rm *.tar
}

mkdir esp
7z e rust-${RustVersion}-${DefaultHost}.tar.xz
7z x rust-${RustVersion}-${DefaultHost}.tar
pushd rust-${RustVersion}-${DefaultHost}
cp -Recurse .\rustc\bin ..\esp\
cp -Recurse .\rustc\lib ..\esp\
cp -Recurse .\rustc\share ..\esp\
cp -ErrorAction SilentlyContinue -Recurse .\rust-std-${DefaultHost}\lib\* ..\esp\lib\
popd
7z e rust-src-${RustVersion}.tar.xz
7z x rust-src-${RustVersion}.tar
pushd rust-src-${RustVersion}
cp -ErrorAction SilentlyContinue -Recurse .\rust-src\lib\* ..\esp\lib\
popd

# Clean up debug files
Get-ChildItem -Path .\ -Filter *.pdb -Recurse -File -Name| ForEach-Object {
    "Removing: $_"
    Remove-Item -Path $_
}

7z a rust-${ReleaseVersion}-${DefaultHost}.zip esp/
