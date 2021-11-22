function New-AzureADApplication {
    param  (
        [Parameter(Mandatory = $false)]
        [string]$DisplayName,
        [Parameter(Mandatory = $true)]
        [string]$IdentifierUris,
        [Parameter(Mandatory = $false)]
        [string]$HomePage,
        [Parameter(Mandatory = $true)]
        [string]$requiredResourcesAccess
    )
    
    aadApplication = New-AzureADApplication -DisplayName $DisplayName -IdentifierUris $IdentifierUris -HomePage $HomePage -RequiredResourceAccess $requiredResourcesAccess
}

function Get-RequiredResourceAccess {
    #Get Service Principal of Microsoft Graph Resource API 
    $graphSP = Get-AzureADServicePrincipal -All $true | Where-Object { $_.DisplayName -eq 'Microsoft Graph' }
    
    #Initialize RequiredResourceAccess for Microsoft Graph Resource API 
    $requiredGraphAccess = New-Object Microsoft.Open.AzureAD.Model.RequiredResourceAccess
    $requiredGraphAccess.ResourceAppId = $graphSP.AppId
    $requiredGraphAccess.ResourceAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.ResourceAccess]
    
    #Set Application Permissions
    $ApplicationPermissions = @('User.Read.All', 'Reports.Read.All')
    
    #Add app permissions
    ForEach ($permission in $ApplicationPermissions) {
        $reqPermission = $null
        #Get required app permission
        $reqPermission = $graphSP.AppRoles | Where-Object { $_.Value -eq $permission }
        if ($reqPermission) {
            $resourceAccess = New-Object Microsoft.Open.AzureAD.Model.ResourceAccess
            $resourceAccess.Type = 'Role'
            $resourceAccess.Id = $reqPermission.Id    
            #Add required app permission
            $requiredGraphAccess.ResourceAccess.Add($resourceAccess)
        }
        else {
            Write-Host "App permission $permission not found in the Graph Resource API" -ForegroundColor Red
        }
    }
    
    #Set Delegated Permissions
    $DelegatedPermissions = @('Directory.Read.All', 'Group.ReadWrite.All') #Leave it as empty array if not required
    
    #Add delegated permissions
    ForEach ($permission in $DelegatedPermissions) {
        $reqPermission = $null
        #Get required delegated permission
        $reqPermission = $graphSP.Oauth2Permissions | Where-Object { $_.Value -eq $permission }
        if ($reqPermission) {
            $resourceAccess = New-Object Microsoft.Open.AzureAD.Model.ResourceAccess
            $resourceAccess.Type = 'Scope'
            $resourceAccess.Id = $reqPermission.Id    
            #Add required delegated permission
            $requiredGraphAccess.ResourceAccess.Add($resourceAccess)
        }
        else {
            Write-Host "Delegated permission $permission not found in the Graph Resource API" -ForegroundColor Red
        }
    }
    
    #Add required resource accesses
    $requiredResourcesAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.RequiredResourceAccess]
    $requiredResourcesAccess.Add($requiredGraphAccess)
    
    return $requiredResourcesAccess
   
}

function Set-RequiredResourcesAccess {
    #Set permissions in existing Azure AD App
    $appObjectId = $aadApplication.ObjectId
    #$appObjectId="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    Set-AzureADApplication -ObjectId $appObjectId -RequiredResourceAccess $requiredResourcesAccess
}

function New-ServicePrincipal {
    #Provide Application (client) Id
    $appId = $aadApplication.AppId
    #$appId="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    $servicePrincipal = New-AzureADServicePrincipal -AppId $appId -Tags @('WindowsAzureActiveDirectoryIntegratedApp')   
    return $servicePrincipal
}

function Set-ApplicationConsent {
    $appObjectId = $aadApplication.ObjectId
    #$appObjectId="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    $requiredResourcesAccess = (Get-AzureADApplication -ObjectId $appObjectId).RequiredResourceAccess

    ForEach ($resourceAppAccess in $requiredResourcesAccess) {
        $resourceApp = Get-AzureADServicePrincipal -All $true | Where-Object { $_.AppId -eq $resourceAppAccess.ResourceAppId }
        ForEach ($permission in $resourceAppAccess.ResourceAccess) {
            if ($permission.Type -eq 'Role') {
                New-AzureADServiceAppRoleAssignment -ObjectId $servicePrincipal.ObjectId -PrincipalId $servicePrincipal.ObjectId -ResourceId $resourceApp.ObjectId -Id $permission.Id
            }
        }
    }
}

function Set-DelegatedConsent {
    # Set ADAL (Microsoft.IdentityModel.Clients.ActiveDirectory.dll) assembly path from Azure AD module location
    $AADModule = Import-Module -Name AzureAD -ErrorAction Stop -PassThru
    $adalPath = Join-Path $AADModule.ModuleBase 'Microsoft.IdentityModel.Clients.ActiveDirectory.dll'
    $adalformPath = Join-Path $AADModule.ModuleBase 'Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll'
    [System.Reflection.Assembly]::LoadFrom($adalPath) | Out-Null
    [System.Reflection.Assembly]::LoadFrom($adalformPath) | Out-Null 
        
    # Azure AD PowerShell client id. 
    $ClientId = '1950a258-227b-4e31-a9cf-717495945fc2'
    $RedirectUri = 'urn:ietf:wg:oauth:2.0:oob'
    $resourceURI = 'https://graph.microsoft.com'
    $authority = 'https://login.microsoftonline.com/common'
    $authContext = New-Object 'Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext' -ArgumentList $authority     
    
    # Get token by prompting login window.
    $platformParameters = New-Object 'Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters' -ArgumentList 'Always'
    $authResult = $authContext.AcquireTokenAsync($resourceURI, $ClientID, $RedirectUri, $platformParameters)
    $accessToken = $authResult.Result.AccessToken
    return $accessToken
}

