if ($IsLinux)
{
    $Default_ConfigDirectory = Join-Path $env:HOME '.powermanager'
}
else
{
    $Default_ConfigDirectory = Join-Path $env:APPDATA 'PowerManager'
}

$logPref = @{
    LogEvent     = $IsLinux -ne $true
    LogEventPref = @{
        LogName   = 'PowerManager'
        LogSource = 'PowerManager'
    }
}

Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -InvalidCertificateAction Ignore -Scope Session -Confirm:$false | Out-Null

#
#region Preferences
#

function Get-PMPrefPath
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name
    )

    process
    {
        return Join-Path $Default_ConfigDirectory "pm$($Name.ToLower()).json"
    }
}

function Get-PMPref
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [ValidateSet('Host', 'Datastore', 'VmExclusion')]
        [string]$Name,
        $InputObject,
        [switch]$File
    )

    begin
    {
        $prefParam = @{
            PrefFilePath   = Get-PMPrefPath $Name
            PrefFileFormat = 'json'
        }

        if (!$File)
        {
            switch ($Name)
            {
                'Host' { $envVarName = 'PM_HOSTS' }
                'Datastore' { $envVarName = 'PM_DATASTORES' }
                'VmExclusion' { $envVarNAme = 'PM_EXCLUSIONS' }
            }

            $prefParam += @{
                InputObject = $InputObject
                VarName     = $envVarName
                Delimiter   = ','
            }
        }
    }

    process
    {
        Get-Pref @prefParam
    }
}

function Add-PMPref
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [ValidateSet('Host', 'Datastore', 'VmExclusion')]
        [string]$Name,
        $InputObject
    )

    begin
    {
        $prefPath = Get-PMPrefPath $Name

        $prefList = @()
        Get-PMPref $Name -File | ForEach-Object { $prefList += $_ }
    }

    process
    {
        if ($InputObject -inotin $prefList)
        {
            $prefList += $InputObject
            Set-Pref -Content $prefList -Path $prefPath -Format json
        }
        else
        {
            Write-Warning "$Name $InputObject already exists in power manager!"
        }
    }
}

function Remove-PMPref
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [ValidateSet('Host', 'Datastore', 'VmExclusion')]
        [string]$Name,
        $InputObject
    )

    begin
    {
        $prefPath = Get-PMPrefPath $Name

        $prefList = @()
        Get-PMPref $Name -File | ForEach-Object { $prefList += $_ }
    }

    process
    {
        if ($InputObject -iin $prefList)
        {
            $newPrefList = @()
            $prefList | Where-Object { $_ -ine $InputObject } | ForEach-Object { $newPrefList += $_ }

            Set-Pref -Content $newPrefList -Path $prefPath -Format json
        }
    }
}

#
#endregion
#

#
#region Credentials
#

function Get-PMCredentialPath([string]$Name) { return Join-Path $Default_ConfigDirectory "cred_$Name.clixml" }
function Test-PMCredentialPath([string]$Name)
{
    if (Test-Path (Get-PMCredentialPath $Name)) { return $true }
    else { return $false }
}

function Get-PMCredential
{
    [cmdletbinding()]
    param(
        [string]$PMHost,
        [pscredential]$Credential
    )

    begin
    {
        $hasEnvVar = $false
        $varNameUser = 'PM_USERNAME'
        $varNamePass = 'PM_PASSWORD'

        # Get default values
        if (($username = Get-Pref -VarName $varNameUser) -and ($password = Get-Pref -VarName $varNamePass))
        {
            Write-Verbose "Found default credentials from env vars"
            $hasEnvVar = $true
            $varCredPw = ConvertTo-SecureString $password -AsPlainText -Force
            $varCredential = [pscredential]::new($username, $varCredPw)
        }

        if (Test-PMCredentialPath 'default')
        {
            Write-Verbose "Found default credentials from file"
            $hasFileVar = $true
            $fileVarPath = Get-PMCredentialPath 'default'
        }

        # If a host is defined, replace default values with host values
        if ($PMHost)
        {
            if (($username = Get-Pref -VarName "$varNameUser`_$PMHost") -and ($password = Get-Pref -VarName "$varNamePass`_$PMHost"))
            {
                Write-Verbose "Found host credentials from env vars"
                $hasEnvVar = $true
                $varCredPw = ConvertTo-SecureString $password -AsPlainText -Force
                $varCredential = [pscredential]::new($username, $varCredPw)
            }

            if (Test-PMCredentialPath $PMHost)
            {
                Write-Verbose "Found host credentials from file"
                $hasFileVar = $true
                $fileVarPath = Get-PMCredentialPath $PMHost
            }
        }
        else
        {
            $PMHost = 'default'
        }
    }

    process
    {
        if ($Credential)
        {
            Write-Verbose "Returning input credentials"
            return $Credential
        }
        elseif ($hasEnvVar)
        {
            Write-Verbose "Returning env credentials"
            return $varCredential
        }
        elseif ($hasFileVar)
        {
            Write-Verbose "Returning file credentials"
            try
            {
                $filePref = Get-Pref -PrefFilePath $fileVarPath -PrefFileFormat clixml
                return ([pscredential]$filePref)
            }
            catch
            {
                throw "Malformed credential file $prefPath`: $($_.Exception.Message)"
            }
        }
        else
        {
            throw "No credential providers found for $PMHost"
        }
    }
}

function Set-PMCredential
{
    [cmdletbinding()]
    param(
        [string]$PMHost = 'default',
        [pscredential]$Credential = (Get-Credential -Message "Enter credentials to manage ESX server $PMHost"),

        [switch]$Force,
        [switch]$Passthru
    )

    begin
    {
        $prefPath = Get-PMCredentialPath $PMHost
    }

    process
    {
        Set-Pref -Content $Credential -Path $prefPath -Format clixml
        if ($Passthru) { Write-Output $Credential }
    }
}

#
#endregion
#

#
#region Connection
#

function Connect-PMHost
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string[]]$PMHost,
        [pscredential]$Credential,
        [switch]$PassThru
    )

    process
    {
        foreach ($hostName in $PMHost)
        {
            if (!$Credential) { $Credential = Get-PMCredential $hostName }

            $connected = $false
            while (!$connected)
            {
                if ($connection = Connect-VIServer $hostName -Credential $Credential -ErrorAction Continue)
                {
                    $connected = $true
                    if ($PassThru)
                    {
                        Write-Output $connection
                    }
                }
                else
                {
                    Write-Warning "Still waiting to connect to $hostName..."
                    Start-Sleep -Seconds 30
                }
            }
        }
    }
}

function Disconnect-PMHost
{
    [cmdletbinding()]
    param(
        [string[]]$PMHost
    )

    process
    {
        foreach ($hostName in $PMHost)
        {
            Disconnect-VIServer $hostName -Confirm:$false -ErrorAction Continue
        }
    }
}

#
#endregion
#

#
# Nothing above here should use these functions
#region Output
#

function Write-PMOutput
{
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Content,
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Type = 'INFO'
    )

    begin
    {
        $oldInfoPref = $InformationPreference
        $InformationPreference = 'Continue'
    }

    process
    {
        foreach ($message in $Content)
        {
            Write-LogTee @logPref -Message $message -LogType $Type
        }
    }

    end
    {
        $InformationPreference = $oldInfoPref
    }
}

#
#endregion
#

#
#region PMJob
#

function Get-PMJob
{
    [cmdletbinding()]
    param(
        [string]$Category = '*'
    )

    process
    {
        Get-PSBackgroundJob -Module 'PowerManager' -Category $Category
    }
}

function Start-PMJob
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory, Position=0)]
        [string]$PMHost,

        [parameter(Position = 1)]
        [string[]]$DatastoreList,

        [parameter(Position = 2)]
        [string[]]$VmExclusionList,

        [parameter(Position = 3)]
        [pscredential]$Credential,

        [parameter(Position = 4)]
        [timespan]$PollingInterval = "00:00:30",

        [parameter(Position = 5)]
        [bool]$Wait = $false
    )

    begin
    {
        $lastDsRescan = [datetime]::MinValue
        $vmParam = @{}

        if ($DatastoreList)
        {
            $dsConnected = $false
            $vmParam.Add('Datastore', $DatastoreList)
        }
        else
        {
            $dsConnected = $true
        }

        Write-PMOutput "Connecting to $PMHost"
        $connection = Connect-PMHost $PMHost -Credential $Credential -PassThru
    }

    process
    {
        while ($dsConnected -eq $false)
        {
            $connectedDatastores = Get-Datastore -Server $PMHost | Where-Object { $_.Name -iin $DatastoreList } | Select-Object -ExpandProperty Name
            if (!(Compare-Object $connectedDatastores $DatastoreList))
            {
                $dsConnected = $true
            }

            if (!$dsConnected)
            {
                if ($lastDsRescan -lt (Get-Date).AddMinutes(-5))
                {
                    Write-PMOutput "Rescanning storage adapters on $PMHost"
                    Get-VMHostStorage -RescanAllHba -Server $PMHost | Out-Null
                }

                Start-Sleep -Seconds 30
            }
        }

        # Get powered off VMs
        $vmList = Get-VM @vmParam |
                    Where-Object { $_.PowerState -ieq 'PoweredOff' } |
                    Where-Object {
                        $vmName = $_.Name
                        $include = $true

                        foreach ($excl in $vmExclusionList)
                        {
                            if ($vmName -ilike $excl)
                            {
                                $include = $false
                                break
                            }
                        }

                        $include
                    }

        $vmCount = $vmList | Measure-Object | Select-Object -ExpandProperty Count
        Write-PMOutput "Starting $vmCount vm(s) on host $pmHost..."
        if ($vmCount -gt 0) { Write-PMOutput "vm(s): $($vmList -join ', ')" }
        $vmList | Start-VM

        while ($Wait -and $connection.IsConnected)
        {
            Start-Sleep -Seconds $PollingInterval.Seconds
        }

        Write-PMOutput "Disconnected from host $PMHost"
    }
}

#
#endregion
#

#
# Main functionality
#

<#

.SYNOPSIS
Ensure VMs are powered-on on a VMWare ESXi host

.DESCRIPTION
Power on VMs on a VMWare ESXi server

.PARAMETER PMHost
VMWare hosts to connect to and power on VMs

.PARAMETER Datastore
Datastores that must be available before continuing with VM power-on operations

.PARAMETER Exclusions
VMs to ignore when performing power-on operations

.PARAMETER Credential
Credentials to use when connecting to VMWare ESXi hosts

.PARAMETER Wait
Continuously monitor connection state to ESXi hosts and power on VMs if connection is lost

.PARAMETER ConfigRefresh
Enable periodic configuration refresh

.PARAMETER ConfigRefreshInterval
The minimum amount of time to wait between configuration refreshes when ConfigRefresh is enabled

.PARAMETER PollingInterval
The minimum amount of time between host connecivity checks

.PARAMETER OutputInterval
The minimum amount of time between job status checks

.EXAMPLE
# Run PowerManager using pre-configured parameters
Start-PowerManager

.EXAMPLE
# Continuously monitor hosts using pre-configured parameters
Start-PowerManager -Wait

.EXAMPLE
# Same as above, but with configuration refresh enabled and extended connectivity check interval
Start-PowerManager -Wait -ConfigRefresh -PollingInterval '00:05:00'

.EXAMPLE
# Run for host 10.0.50.11 and credentials from input
$hostCredential = Get-Credential
Start-PowerManager -PmHost 10.0.50.11 -Credential $hostCredential

#>
function Start-PowerManager
{
    [cmdletbinding()]
    param(
        [string[]]$PMHost,
        [string[]]$Datastore,
        [string[]]$Exclusion,
        [pscredential]$Credential,

        [switch]$Wait,

        [switch]$ConfigRefresh,
        [ValidateNotNullOrEmpty()]
        [timespan]$ConfigRefreshInterval = "01:00:00",

        [ValidateNotNullOrEmpty()]
        [timespan]$PollingInterval = "00:00:30",

        [ValidateNotNullOrEmpty()]
        [timespan]$OutputInterval = "00:00:10"
    )

    begin
    {
        $firstRun = $true
        $lastConfigRefresh = [datetime]::MinValue

        Get-PMJob -Category PMHost | Remove-PsBackgroundJob -Force

        $jobArgList = @(
            $Datastore,
            $Exclusion,
            $Credential,
            $PollingInterval,
            $Wait
        )
    }

    process
    {
        while ($firstRun -or (Get-PMJob -Category PMHost))
        {
            # Refresh config
            $currentTime = Get-Date
            $needsRefresh = $lastConfigRefresh -lt ($currentTime - $ConfigRefreshInterval)
            if ($firstRun -or ($ConfigRefresh -and $needsRefresh))
            {
                $hostList = Get-PmPref -Name Host -InputObject $PMHost
                $hostCount = $hostList | Measure-Object | Select-Object -ExpandProperty Count
                Write-PMOutput "Hosts ($hostCount): $($hostList -join ', ')"

                $dsList = Get-PmPref -Name Datastore -InputObject $Datastore
                $dsCount = $dsList | Measure-Object | Select-Object -ExpandProperty Count
                Write-PMOutput "Datastores ($dsCount): $($dsList -join ', ')"

                $vmExclusionList = Get-PMPref -Name VmExclusion -InputObject $Exclusion
                $vmExclusionCount = $vmExclusionList | Measure-Object | Select-Object -ExpandProperty Count
                Write-PMOutput "Exclusions ($vmExclusionCount): $($vmExclusionList -join ', ')"

                $lastConfigRefresh = Get-Date
            }

            try
            {
                # Receive job output
                Get-PMJob -Category PMHost | Receive-PsBackgroundJob

                # Remove completed jobs
                Get-PMJob -Category PMHost | Where-Object { $_.Status -ine 'running' } | Remove-PSBackgroundJob

                # Start new jobs if needed
                if ($FirstRun -or $Wait)
                {
                    $jobList = Get-PMJob -Category PMHost
                    $hostList |
                        Where-Object { $_ -inotin $jobList.Name } |
                        ForEach-Object {
                            Start-PsBackgroundJob -Name $_ `
                                -Module PowerManager -Category PMHost `
                                -ScriptBlock ${Function:Start-PMJob} -ArgumentList (@($_) + $jobArgList) `
                                -PassThru
                            } |
                            Out-Null
                }
            }
            catch
            {
                Write-PMOutput -Content "Unhandled error: $($_.Exception.Message)" -Type ERROR
            }
            finally
            {
                $firstRun = $false
            }

            if ($Wait -or (Get-PMJob -Category PMHost))
            {
                Start-Sleep -Seconds $OutputInterval.Seconds
            }
        }
    }
}
