# Helper script to perform repackaging of Windows release

# Stop on error
$ErrorActionPreference = "Stop"

$RustVersion="nightly"
$ReleaseVersion="1.60.0.0"

if (Test-Path -Path esp -PathType Container) {
    Remove-Item -Recurse -Force -Path esp
    rm *.tar
}

mkdir esp
7z e rust-${RustVersion}-x86_64-pc-windows-msvc.tar.xz
7z x rust-${RustVersion}-x86_64-pc-windows-msvc.tar
pushd rust-${RustVersion}-x86_64-pc-windows-msvc
cp -Recurse .\rustc\bin ..\esp\
cp -Recurse .\rustc\lib ..\esp\
cp -Recurse .\rustc\share ..\esp\
cp -ErrorAction SilentlyContinue -Recurse .\rust-std-x86_64-pc-windows-msvc\lib\* ..\esp\lib\
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

7z a rust-${ReleaseVersion}-x86_64-pc-windows-msvc.zip esp/
