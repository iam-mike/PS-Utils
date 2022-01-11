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
#   specified at http://www.microsoft.com/info/cppyright.htm.               # 
#                                                                           #  
#   Author: Mike Witts                                                      #  
#   Version 0.1         Date Last Modified: 30 November 2021                #  
#                                                                           #  
#############################################################################  
#>
# Parameter help description
param ($OUTPUTDIR = "$(Get-Location)\$(Get-Date -Format yyyyMMdd)")
Write-Host "output to be saved in $OUTPUTDIR"

if (!(Test-Path $OUTPUTDIR)) {
    Write-Host 'creating output directory' -ForegroundColor yellow
    try {
        mkdir $OUTPUTDIR 
        mkdir $OUTPUTDIR\Policies
    } 
    catch { 
        Write-Host 'error creating output directory. EXITING' -ForegroundColor red
        Break Script
    }
}
else {
    $continue = Read-Host 'output directory already exists. are you sure you want to overwrite? (y/N)'
    if ($continue -eq 'y') {
        Write-Host 'overwriting output directory' -ForegroundColor yellow
        try {
            Remove-Item $OUTPUTDIR
            mkdir $OUTPUTDIR\Policies
        } 
        catch { 
            Write-Host 'error recreating output directory. EXITING' -ForegroundColor red 
            Break Script
        }
    }
    else {
        Write-Host 'exiting' -ForegroundColor red 
        #[Environment]::Exit(0)
        Break Script
    }
    #Read-Host 'output directory already exists. OVERWRIT' -ForegroundColor red
}
    
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
$edition = $PSVersionTable.PSEdition
$OS = $Env:OS
if ($edition -eq 'Desktop') {
    Import-Module AzureAD
    Write-Host 'using powershell desktop edition' -ForegroundColor green
}
elseif ($IsWindows) {
    <#Try { 
        write-host "TRY BLOCK"
        Import-Module AzureAD -UseWindowsPowerShell -ErrorAction Continue 
        Write-Host 'using windows powershell' -ForegroundColor Yellow
    }
    Catch { 
        write-host "CATCH BLOCK"
        Import-Module AzureADPreview 
    }#>
    if (Get-Module -ListAvailable -Name AzureAD) {
        Import-Module AzureAD -UseWindowsPowerShell 
    } elseif (Get-Module -ListAvailable -Name AzureADPreview)
    {
        Import-Module AzureADPreview -UseWindowsPowerShell
    }
    else {
        Write-Host 'no Azure AD powershell module found.' -ForegroundColor red
        Write-Host 'Resolve by installing module AzureAD. More information can be found at https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2' -ForegroundColor red
        Write-Host 'EXITING' -ForegroundColor red
        Break Script
    }
}   
else {
    Write-Host 'This script is only supported on Windows and Desktop Powershell. And may not work on other systems' -ForegroundColor red
    Import-Module AzureADPreview
    Write-Host 'using powershell preview' -ForegroundColor Red
}
Connect-AzureAD # connect

#endregion

#region data collection

#region applications

# Get existing azure ad applications and servce principals
$Applications = Get-AzureADApplication -All:$true
$ServicePrincipals = Get-AzureADServicePrincipal -All:$true | Where-Object { $_.Tags -eq 'WindowsAzureActiveDirectoryIntegratedApp' }
foreach ($ServicePrincipal in $ServicePrincipals.ObjectId) {
    $DelegatedPermissions = Get-AzureADApplicationDelegatedPermissions -ServicePrincipalId $ServicePrincipal
    $ApplicationPermissions = Get-AzureADApplicationPermission -ServicePrincipalId $ServicePrincipal
    $ApplicationUsers = Get-AzureADApplicationUsers -ServicePrincipalId $ServicePrincipal
}
#endregion

#region CA Policies
$AllPolicies = Get-AzureADMSConditionalAccessPolicy

foreach ($Policy in $AllPolicies) {
    $policyLocation = "$OUTPUTDIR\Policies\POLICY-$($Policy.DisplayName).json"
    Write-Output "Backing up $($Policy.DisplayName)"
    $JSON = $Policy | ConvertTo-Json -Depth 10 | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) } 
    $JSON | Out-File $policyLocation
}
#endregion

#endregion

#endregion

#region output

$DelegatedPermissions = @{}
$ApplicationPermissions = @{}
$ApplicationUsers = @{}
foreach ($ServicePrincipal in $ServicePrincipals.ObjectId) {
    $DelegatedPermission = Get-AzureADApplicationDelegatedPermissions -ServicePrincipalId $ServicePrincipal
    $DelegatedPermissions.Add($ServicePrincipal, $DelegatedPermission)
    $ApplicationPermission = Get-AzureADApplicationPermission -ServicePrincipalId $ServicePrincipal
    $ApplicationPermissions.Add($ServicePrincipal, $ApplicationPermission)
    $ApplicationUser = Get-AzureADApplicationUsers -ServicePrincipalId $ServicePrincipal
    $ApplicationUsers.Add($ServicePrincipal, $ApplicationUser)
}


$Applications | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) } | Out-File "$OUTPUTDIR\application-details.json" -Encoding utf8
$Applications | Out-File "$OUTPUTDIR\applications.csv"
$ServicePrincipals | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) } | Out-File "$OUTPUTDIR\service-principals.json" -Encoding utf8
$DelegatedPermissions | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) } | Out-File "$OUTPUTDIR\delegated-permissions.json" -Encoding utf8
$ApplicationUsers | ConvertTo-Json | Out-File "$OUTPUTDIR\application-users.json" -Encoding utf8
$ApplicationPermissions | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) } | Out-File "$OUTPUTDIR\application-permissions.json" -Encoding utf8 

#endregion

#region cleanup

Disconnect-AzureAD # Disconnect from old session
# Remove-Variable Applications, ServicePrincipals, DelegatedPermissions, ApplicationPermissions, ApplicationUsers

#endregion