[cmdletbinding()]
param()

begin
{
    $oldInfoPref = $InformationPreference
    $oldProgressPref = $ProgressPreference
    $oldWarningPref = $WarningPreference
    $InformationPreference = 'Continue'
    $ProgressPreference = 'SilentlyContinue'
    $WarningPreference = 'SilentlyContinue'
}

process
{
    Write-Information "Installing prerequisites..."
    if (!(Get-PackageProvider NuGet -ErrorAction SilentlyContinue)) { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force }
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module VMWare.PowerCLI -Confirm:$false -Scope CurrentUser

    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -ParticipateInCeip:$false -Confirm:$false | Out-Null
}

end
{
    $InformationPreference = $oldInfoPref
    $ProgressPreference = $oldProgressPref
    $WarningPreference = $oldWarningPref
}
