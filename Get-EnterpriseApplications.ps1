#Install-Module AzureAD
Import-Module AzureAD -UseWindowsPowerShell

Connect-AzureAD # connect

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

# Get existing azure ad applications and servce principals
$Applications = Get-AzureADApplication -All:$true
$ServicePrincipals = Get-AzureADServicePrincipal -All:$true | Where-Object { $_.Tags -eq 'WindowsAzureActiveDirectoryIntegratedApp' }
<#
foreach ($ServicePrincipal in $ServicePrincipals[1].ObjectId) {
    $DelegatedPermissions = Get-AzureADApplicationDelegatedPermissions -ServicePrincipalId $ServicePrincipal
    $ApplicationPermissions = Get-AzureADApplicationPermission -ServicePrincipalId $ServicePrincipal
    $ApplicationUsers = Get-AzureADApplicationUsers -ServicePrincipalId $ServicePrincipal
}
#>
    $DelegatedPermissions = Get-AzureADApplicationDelegatedPermissions -ServicePrincipalId $ServicePrincipals[1].ObjectId
    $ApplicationPermissions = Get-AzureADApplicationPermission -ServicePrincipalId $ServicePrincipals[1].ObjectId
    $ApplicationUsers = Get-AzureADApplicationUsers -ServicePrincipalId $ServicePrincipals[1].ObjectId

Disconnect-AzureAD # Disconnect from old session and create new
Connect-AzureAD # connect
foreach ($application in $Applications[0]) {
    New-AzureAdApplication -Displayname $application.DisplayName -IdentifierUris $application.IdentifierUris -HomePage $application.HomePage -LogoutUrl $application.LogoutUrl
    ## TODO: Add displayed owners
    # Add-AzureADApplicationOwner -OjbectID application.ObjectId -OwnerObjectId owner.ObjectId
    ## TODO: Add delegated permissions
    ## TODO: Add permissions
    # TODO:
}