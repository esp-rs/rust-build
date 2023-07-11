winget install --id Git.Git --accept-source-agreements
winget install --id MSYS2.MSYS2
winget install --id 7zip.7zip

setx /M PATH "$env:PATH;C:\Program Files\7-Zip;C:\Program Files\Git\bin"

c:\msys64\msys2_shell.cmd -mingw64
