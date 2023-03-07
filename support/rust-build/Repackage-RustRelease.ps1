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
$ReleaseVersion="1.68.0.0"

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

7z e cargo-${RustVersion}.tar.xz
7z x cargo-${RustVersion}.tar
pushd cargo-${RustVersion}
cp -ErrorAction SilentlyContinue -Recurse .\cargo\bin\* ..\esp\bin\
cp -ErrorAction SilentlyContinue -Recurse .\cargo\libexec ..\esp\
popd

7z e clippy-${RustVersion}.tar.xz
7z x clippy-${RustVersion}.tar
pushd clippy-${RustVersion}
cp -ErrorAction SilentlyContinue -Recurse .\clippy-preview\bin\* ..\esp\bin\
popd

7z e rustfmt-${RustVersion}.tar.xz
7z x rustfmt-${RustVersion}.tar
pushd rustfmt-${RustVersion}
cp -ErrorAction SilentlyContinue -Recurse .\rustfmt-preview\bin\* ..\esp\bin\
popd

# Clean up debug files
Get-ChildItem -Path .\ -Filter *.pdb -Recurse -File -Name| ForEach-Object {
    "Removing: $_"
    Remove-Item -Path $_
}

7z a rust-${ReleaseVersion}-${DefaultHost}.zip esp/
