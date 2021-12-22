# VMWare VM Power Manager
PowerShell module to ensure VMs are powered on after loss of connection to a VMWare ESXi host.

[Module usage](Hobo.PowerManager/README.md)

[Module configuration](Hobo.PowerManager/CONFIG.md)

[Install with Ansible](ansible/README.md)

## Container Management
### Build the Container
`docker build . -t ghcr.io/hobointhecorner/hobo.powermanager:stable`

### Run the Container
`docker run gchr.io/hobointhecorner/hobo.powermanager:stable Start-PowerManager`
