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

#region functions
function Get-AzureADApplicationDelegatedPermissions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServicePrincipalId
    )
    $DelegatedPermissions = Get-AzureADServicePrincipalOAuth2PermissionGrant -ObjectId $ServicePrincipalId
    return $DelegatedPermissions
}

function Get-AzureADApplicationPermission {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServicePrincipalId
    )
    $AppPermissions = @()
    $ResourceAppHash = @{}
    $AppRoleAssignments = Get-AzureADServiceAppRoleAssignedTo -ObjectId $ServicePrincipalId
    $AppRoleAssignments | ForEach-Object {
        $RoleAssignment = $_
        $AppRoles = {}
        If ($ResourceAppHash.ContainsKey($RoleAssignment.ResourceId)) {
            $AppRoles = $ResourceAppHash[$RoleAssignment.ResourceId]
        }
        Else {
            $AppRoles = (Get-AzureADServicePrincipal -ObjectId $RoleAssignment.ResourceId).AppRoles
            #Store AppRoles to re-use.
            #Probably all role assignments use the same resource (Ex: Microsoft Graph).
            $ResourceAppHash[$RoleAssignment.ResourceId] = $AppRoles
        }
        $AppliedRole = $AppRoles | Where-Object { $_.Id -eq $RoleAssignment.Id }  
        $AppPermissions += New-Object PSObject -Property @{
            DisplayName  = $AppliedRole.DisplayName
            Roles        = $AppliedRole.Value
            Description  = $AppliedRole.Description
            IsEnabled    = $AppliedRole.IsEnabled
            ResourceName = $RoleAssignment.ResourceDisplayName
        }
    }
    return $AppPermissions
}

function Get-AzureADApplicationUsers {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServicePrincipalId
    )
    $Users = Get-AzureADServiceAppRoleAssignment -ObjectId $ServicePrincipalId
    return $Users
}

#endregion

#region Main
#Install-Module AzureAD
Import-Module AzureAD -UseWindowsPowerShell
Connect-AzureAD # connect

#endregion

#region data collection

# Get existing azure ad applications and servce principals
$Applications = Get-AzureADApplication -All:$true
$ServicePrincipals = Get-AzureADServicePrincipal -All:$true | Where-Object { $_.Tags -eq 'WindowsAzureActiveDirectoryIntegratedApp' }
$DelegatedPermissions = Get-AzureADApplicationDelegatedPermissions -ServicePrincipalId $ServicePrincipals[3].ObjectId
$ApplicationPermissions = Get-AzureADApplicationPermission -ServicePrincipalId $ServicePrincipals[11].ObjectId
$ApplicationUsers = Get-AzureADApplicationUsers -ServicePrincipalId $ServicePrincipals[2].ObjectId

#endregion

#region output
$Applications | ConvertTo-Json -AsArray | % { [System.Text.RegularExpressions.Regex]::Unescape($_) } | Out-File "c:\temp\application-details.json" -Encoding utf8
$Applications | Out-File "c:\temp\applications.csv"
$ServicePrincipals | ConvertTo-Json -AsArray | % { [System.Text.RegularExpressions.Regex]::Unescape($_) } | Out-File "c:\temp\service-principals.json" -Encoding utf8
$DelegatedPermissions | ConvertTo-Json -AsArray | % { [System.Text.RegularExpressions.Regex]::Unescape($_) } | Out-File "c:\temp\delegated-permissions.json" -Encoding utf8
$ApplicationUsers | ConvertTo-CSV | Out-File "c:\temp\application-users.csv" -Encoding utf8

<# REMOVED TO PREVENT LOOPING
foreach ($ServicePrincipal in $ServicePrincipals.ObjectId) {
    $DelegatedPermissions = Get-AzureADApplicationDelegatedPermissions -ServicePrincipalId $ServicePrincipal
    $ApplicationPermissions = Get-AzureADApplicationPermission -ServicePrincipalId $ServicePrincipal
    $ApplicationUsers = Get-AzureADApplicationUsers -ServicePrincipalId $ServicePrincipal
}
#>
#endregion

#region cleanup

Disconnect-AzureAD # Disconnect from old session
# Remove-Variable Applications, ServicePrincipals, DelegatedPermissions, ApplicationPermissions, ApplicationUsers

#endregion



#region testing - move below section into new script when matured
Connect-AzureAD # connect
    foreach ($application in $Applications[0]) {
        New-AzureAdApplication -Displayname $application.DisplayName -IdentifierUris $application.IdentifierUris -HomePage $application.HomePage -LogoutUrl $application.LogoutUrl
        ## TODO: Add displayed owners
        # Add-AzureADApplicationOwner -OjbectID application.ObjectId -OwnerObjectId owner.ObjectId
        ## TODO: Add delegated permissions
        ## TODO: Add permissions
        # TODO:
    } 
Disconnect-AzureAD # Disconnect from old session
#endregion



#region testing

# Get existing azure ad applications and servce principals

function Get-AppsAndData {
    $FirstPartyApps = Get-AzureADApplication -All:$true | Where-Object { $_.Tags -ne 'WindowsAzureActiveDirectoryIntegratedApp' }
    $ThirdPartyApps = Get-AzureADServicePrincipal -All:$true | Where-Object { $_.Tags -eq 'WindowsAzureActiveDirectoryIntegratedApp' }
    $Apps = ($FirstPartyApps + $ThirdPartyApps) 
    Return $Apps
    # $Apps | Format-List Select-Object DisplayName, AppID, PublicClient, AvailableToOtherTenants, HomePage, LogoutUrl  | Export-Csv "C:\temp\AzureADApps.csv"  -NoTypeInformation -Encoding UTF8
}

# joining apps
Foreach ($3PApp in $ThirdPartyApps) {
    Write-Host $3PApp.AppID
    foreach ($1PApp in $FirstPartyApps) {
        if ($1PApp.AppId -ne $3PApp.AppId) {
            Write-Host $
        }
    }
}

#endregion