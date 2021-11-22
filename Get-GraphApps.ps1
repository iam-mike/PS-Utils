
<#
#############################################################################  
#                                                                           #  
#   This Sample Code is provided for the purpose of illustration only       #  
#   and is not intended to be used in a production environment.  THIS       #  
#   SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT    #  
#   WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT    #  
#   LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS     #  
#   FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free    #  
#   right to use and modify the Sample Code and to reproduce and distribute #  
#   the object code form of the Sample Code, provided that You agree:       #  
#   (i) to not use Our name, logo, or trademarks to market Your software    #  
#   product in which the Sample Code is embedded; (ii) to include a valid   #  
#   copyright notice on Your software product in which the Sample Code is   #  
#   embedded; and (iii) to indemnify, hold harmless, and defend Us and      #  
#   Our suppliers from and against any claims or lawsuits, including        #  
#   attorneys' fees, that arise or result from the use or distribution      #  
#   of the Sample Code.                                                     # 
#                                                                           # 
#   This posting is provided "AS IS" with no warranties, and confers        # 
#   no rights. Use of included script samples are subject to the terms      # 
#   specified at http://www.microsoft.com/info/cpyright.htm.                # 
#                                                                           #  
#   Author: Mike Witts                                                      #  
#   Version 0.1         Date Last Modified: 22 November 2021                #  
#                                                                           #  
#############################################################################  
#>

install-module microsoft.Graph
ipmo microsoft.Graph
function Get-AuthToken {

    <#
.SYNOPSIS
This function is used to authenticate with the Graph API REST interface
.DESCRIPTION
The function authenticate with the Graph API Interface with the tenant name
.EXAMPLE
Get-AuthToken
Authenticates you with the Graph API interface
.NOTES
NAME: Get-AuthToken
#>

    [cmdletbinding()]

    param
    (
        [Parameter(Mandatory = $true)]
        $User
    )

    $userUpn = New-Object 'System.Net.Mail.MailAddress' -ArgumentList $User

    $tenant = $userUpn.Host

    Write-Host 'Checking for AzureAD module...'

    $AadModule = Get-Module -Name 'AzureAD' -ListAvailable

    if ($AadModule -eq $null) {

        Write-Host 'AzureAD PowerShell module not found, looking for AzureADPreview'
        $AadModule = Get-Module -Name 'AzureADPreview' -ListAvailable

    }

    if ($AadModule -eq $null) {
        Write-Host
        Write-Host 'AzureAD Powershell module not installed...' -f Red
        Write-Host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
        Write-Host "Script can't continue..." -f Red
        Write-Host
        exit
    }

    # Getting path to ActiveDirectory Assemblies
    # If the module count is greater than 1 find the latest version

    if ($AadModule.count -gt 1) {

        $Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]

        $aadModule = $AadModule | Where-Object { $_.version -eq $Latest_Version.version }

        # Checking if there are multiple versions of the same module found

        if ($AadModule.count -gt 1) {

            $aadModule = $AadModule | Select-Object -Unique

        }

        $adal = Join-Path $AadModule.ModuleBase 'Microsoft.IdentityModel.Clients.ActiveDirectory.dll'
        $adalforms = Join-Path $AadModule.ModuleBase 'Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll'

    }

    else {

        $adal = Join-Path $AadModule.ModuleBase 'Microsoft.IdentityModel.Clients.ActiveDirectory.dll'
        $adalforms = Join-Path $AadModule.ModuleBase 'Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll'

    }

    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

    $clientId = 'd1ddf0e4-d672-4dae-b554-9d5bdfd93547'

    $redirectUri = 'urn:ietf:wg:oauth:2.0:oob'

    $resourceAppIdURI = 'https://graph.microsoft.com'

    $authority = "https://login.microsoftonline.com/$Tenant"

    try {

        $authContext = New-Object 'Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext' -ArgumentList $authority

        # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
        # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

        $platformParameters = New-Object 'Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters' -ArgumentList 'Auto'

        $userId = New-Object 'Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier' -ArgumentList ($User, 'OptionalDisplayableId')

        $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters, $userId).Result

        # If the accesstoken is valid then create the authentication header

        if ($authResult.AccessToken) {

            # Creating header for Authorization token

            $authHeader = @{
                'Content-Type'  = 'application/json'
                'Authorization' = 'Bearer ' + $authResult.AccessToken
                'ExpiresOn'     = $authResult.ExpiresOn
            }

            return $authHeader

        }

        else {

            Write-Host
            Write-Host 'Authorization Access Token is null, please re-run authentication...' -ForegroundColor Red
            Write-Host
            break

        }

    }

    catch {

        Write-Host $_.Exception.Message -f Red
        Write-Host $_.Exception.ItemName -f Red
        Write-Host
        break

    }

}

Connect-Graph -Scopes Application.Read.All, Application.ReadWrite.All, Directory.Read.All

# Get-MgApplication
foreach ($application in $Applications[0]) {
    New-AzureAdApplication -Displayname $application.DisplayName -IdentifierUris $application.IdentifierUris -HomePage $application.HomePage -LogoutUrl $application.LogoutUrl
    ## TODO: Add displayed owners
    # Add-AzureADApplicationOwner -OjbectID application.ObjectId -OwnerObjectId owner.ObjectId
    ## TODO: Add delegated permissions
    ## TODO: Add permissions
    # TODO:
}

Disconnect-MgGraph