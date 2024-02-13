# Requires elevation of privileges
$ProgressPreference = 'SilentlyContinue'
Set-ExecutionPolicy Bypass

winget install --id Git.Git --accept-source-agreements
winget install --id 7zip.7zip
winget install --id Python.Python.3.12 --scope machine
winget install --id Kitware.CMake
winget install --id Ninja-build.Ninja --scope machine

wget https://aka.ms/vs/17/release/vs_buildtools.exe -OutFile vs_buildtools.exe
.\vs_buildtools.exe --passive --wait --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.22621

# winget installation failed with an error, using vs_buildtools.exe instead
#winget install -e --id Microsoft.WindowsSDK
#winget install Microsoft.VisualStudio.2022.BuildTools --silent --override "--wait --quiet --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64"

setx /M PATH "$env:PATH;C:\Program Files\7-Zip"

# Register path to system wide Ninja
setx /M PATH="$env:PATH;C:\Program Files\WinGet\Links"
