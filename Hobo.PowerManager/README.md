# Hobo.PowerManager PowerShell Module
Ensures VMs are powered on after loss of connection to an VMWare ESXi host.

## Syntax
```
Start-PowerManager [[-PMHost] <string[]>] [[-Datastore] <string[]>] [[-Exclusion] <string[]>] [[-Credential] <pscredential>]
  [-ConfigRefresh] [[-ConfigRefreshInterval] <timespan>] [[-PollingInterval] <timespan>] [[-OutputInterval] <timespan>] [-Wait]
```

## Examples

```powershell
# Run PowerManager using pre-configured parameters
Start-PowerManager

# Continuously monitor hosts using pre-configured parameters
Start-PowerManager -Wait

# Same as above, but with configuration refresh enabled and extended connectivity check interval
Start-PowerManager -Wait -ConfigRefresh -PollingInterval '00:05:00'

# Run for host 10.0.50.11 and credentials from input
$hostCredential = Get-Credential
Start-PowerManager -PmHost 10.0.50.11 -Credential $hostCredential

# Configure default parameters
## Set esxi hosts
'10.0.50.11', '10.0.50.21', '10.0.50.31' | foreach { Add-PMPref Host $_ }

## Set datastores
'GOLD', 'SILVER', 'BRONZE' | foreach { Add-PMPref Datastore $_ }

## Add default host connection credentials
Set-PMCredential

## Add host-specific credential for 10.0.50.11
Set-PMCredential -PMHost 10.0.50.11

## Exclude server marked for deprecation
Add-PMPref VmExclusion LegacyServer2003
```

## Parameters
*Also see: [List of script parameters](CONFIG.md)*

All script parameters are resolved in the following order of priority:
* Command-line parameters
* Environment variables
* Configuration files

### Configuration Files
You can use `Add/Remove-PMPref` to set default values for the following:
* Host
* Datastore
* VmExclusion

You can use `Set-PMCredential` to set a default fallback credential to connect to hosts or set credentials for individual hosts.

These files are stored in:
* **Windows**: `%appdata%\PowerManager\`
* **Linux**: `$HOME/.powermanager/`
