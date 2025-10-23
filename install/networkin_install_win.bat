#Installation Network-In! Windows

#dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --install --no-distribution

wsl --import NetworkIn ./networkin.tar


