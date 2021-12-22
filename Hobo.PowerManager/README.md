# Hobo.PowerManager PowerShell Module
Ensures VMs are powered on after loss of connection to an VMWare ESXi host.

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

## Usage
```
> get-help Start-PowerManager -Full

NAME
    Start-PowerManager

SYNOPSIS
    Ensure VMs are powered-on on a VMWare ESXi host


SYNTAX
    Start-PowerManager [[-PMHost] <String[]>] [[-Datastore] <String[]>] [[-Exclusion] <String[]>] [[-Credential] <PSCredential>] [-Wait] [-ConfigRefresh] [[-ConfigRefreshInterval] <TimeSpan>] [[-PollingInterval] <TimeSpan>] [[-OutputInterval] <TimeSpan>] [<CommonParameters>]


DESCRIPTION
    Power on VMs on a VMWare ESXi server


PARAMETERS
    -PMHost <String[]>
        VMWare hosts to connect to and power on VMs

        Required?                    false
        Position?                    1
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Datastore <String[]>
        Datastores that must be available before continuing with VM power-on operations

        Required?                    false
        Position?                    2
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Exclusion <String[]>

        Required?                    false
        Position?                    3
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credential <PSCredential>
        Credentials to use when connecting to VMWare ESXi hosts

        Required?                    false
        Position?                    4
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Wait [<SwitchParameter>]
        Continuously monitor connection state to ESXi hosts and power on VMs if connection is lost

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ConfigRefresh [<SwitchParameter>]
        Enable periodic configuration refresh

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ConfigRefreshInterval <TimeSpan>
        The minimum amount of time to wait between configuration refreshes when ConfigRefresh is enabled

        Required?                    false
        Position?                    5
        Default value                01:00:00
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -PollingInterval <TimeSpan>
        The minimum amount of time between host connecivity checks

        Required?                    false
        Position?                    6
        Default value                00:00:30
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -OutputInterval <TimeSpan>
        The minimum amount of time between job status checks

        Required?                    false
        Position?                    7
        Default value                00:00:10
        Accept pipeline input?       false
        Accept wildcard characters?  false

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).
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
