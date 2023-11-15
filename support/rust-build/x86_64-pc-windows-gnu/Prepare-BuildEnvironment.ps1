# Requires elevation of privileges

Set-ExecutionPolicy Bypass

winget install --id Git.Git --accept-source-agreements
winget install --id MSYS2.MSYS2
winget install --id 7zip.7zip
winget install --id Python.Python.3.12 --scope machine

setx /M PATH "$env:PATH;C:\Program Files\7-Zip"

c:\msys64\msys2_shell.cmd -mingw64
