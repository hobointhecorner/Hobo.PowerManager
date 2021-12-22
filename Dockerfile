FROM mcr.microsoft.com/powershell:latest

LABEL org.opencontainers.image.source https://github.com/hobointhecorner/hobo.powermanager

COPY ["Hobo.PowerManager", "/usr/local/share/powershell/Modules/Hobo.PowerManager/"]
RUN pwsh -command /usr/local/share/powershell/Modules/Hobo.PowerManager/Install-PowerManager.ps1

ENTRYPOINT [ "pwsh", "-Command" ]
