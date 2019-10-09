﻿<#
.SYNOPSIS
Enables the Responsive UI on a target SharePoint 2013 or SharePoint 2016 on-premises site collection.

.EXAMPLE
PS C:\> .\Enable-SPResponsiveUI.ps1 -TargetSiteUrl "https://intranet.mydomain.com/sites/targetSite"

.EXAMPLE
PS C:\> $creds = Get-Credential
PS C:\> .\Enable-SPResponsiveUI.ps1 -TargetSiteUrl "https://intranet.mydomain.com/sites/targetSite" -InfrastructureSiteUrl "https://intranet.mydomain.com/sites/infrastructureSite" -Credentials $creds
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true, HelpMessage="Enter the URL of the target site collection, e.g. 'https://intranet.mydomain.com/sites/targetSite'")]
    [String]
    $TargetSiteUrl,

    [Parameter(Mandatory = $false, HelpMessage="Enter the URL of the infrastructural site collection, if any. It is an optional parameter. Values are like: 'https://intranet.mydomain.com/sites/infrastructureSite'")]
    [String]
    $InfrastructureSiteUrl,

    [Parameter(Mandatory=$false, HelpMessage="Deploy on production")]
    [switch]$Prod,

    [Parameter(Mandatory = $false, HelpMessage="Optional administration credentials")]
    [PSCredential]
    $Credentials,

    [Parameter(Mandatory = $false, HelpMessage="Include this switch when connecting to SharePoint with browser based login. This option requires multi-factor authentication (MFA) to be enabled.")]
    [Switch]
    $UseWebLogin
)

if($Credentials -eq $null -and $UseWebLogin -eq $false)
{
	$Credentials = Get-Credential -Message "Enter Admin Credentials"
}

Write-Host -ForegroundColor White "--------------------------------------------------------"
Write-Host -ForegroundColor White "|               Enabling Responsive UI                 |"
Write-Host -ForegroundColor White "--------------------------------------------------------"
Write-Host

try
{
    # Rename minified files by removing .min from file names
    if ($Prod) {
        Copy-Item .\SP-Responsive-UI.css .\SP-Responsive-UI.bck.css
        Copy-Item .\SP-Responsive-UI.js .\SP-Responsive-UI.bck.js
        Copy-Item .\SP-Responsive-UI.min.css .\SP-Responsive-UI.css -Force
        Copy-Item .\SP-Responsive-UI.min.js .\SP-Responsive-UI.js -Force
    }
    Write-Host -ForegroundColor Yellow "Connecting to target site URL: $TargetSiteUrl"
    if ($UseWebLogin) {
        Connect-PnPOnline $TargetSiteUrl -UseWebLogin;
    } else {
        Connect-PnPOnline $TargetSiteUrl -Credentials $Credentials;
    }
    Write-Host -ForegroundColor Yellow "Enabling responsive UI on target site"

    # If the Infrastructure Site URL is provided, we use it
    if ($InfrastructureSiteUrl -ne "") 
    {
        Write-Host -ForegroundColor Yellow "Infrastructure Site URL: $InfrastructureSiteUrl"
        Enable-PnPResponsiveUI -InfrastructureSiteUrl $InfrastructureSiteUrl
    }
    else
    {
        Enable-PnPResponsiveUI

        Write-Host -ForegroundColor Yellow "Uploading custom responsive UI assets to target site"
        Apply-PnPProvisioningTemplate -Path .\Responsive.UI.Infrastructure.xml -Handlers Files
    }
    # Rollback original files
    if ($Prod) {
        Move-Item .\SP-Responsive-UI.bck.css .\SP-Responsive-UI.css -Force
        Move-Item .\SP-Responsive-UI.bck.js .\SP-Responsive-UI.js -Force
    }

    Write-Host -ForegroundColor Green "Responsive UI application succeeded"
}
catch
{
    Write-Host -ForegroundColor Red "Exception occurred!" 
    Write-Host -ForegroundColor Red "Exception Type: $($_.Exception.GetType().FullName)"
    Write-Host -ForegroundColor Red "Exception Message: $($_.Exception.Message)"
}
