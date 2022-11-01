#Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
#choco install msys2 -y

winget install --id Git.Git
winget install --id MSYS2.MSYS2

c:\msys64\msys2_shell.cmd -mingw64
