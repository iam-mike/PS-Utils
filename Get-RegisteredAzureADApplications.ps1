function Initialize-Environment {
    if (!(Get-Module -ListAvailable -Name AzureAD)) {
        Write-Host 'Module does not exist installing'
        try {
            Install-Module AzureAD -UseWindowsPowerShell -ErrorAction SilentlyContinue 
        }
        catch {
            Install-Module AzureAD
        }
    } 
    try {
        Import-Module AzureAD -UseWindowsPowerShell -ErrorAction SilentlyContinue
    }
    catch {
        Import-Module AzureAD 
    }
    Connect-AzureAD
}


function Get-AppsAndData {
    $FirstPartyApps = Get-AzureADApplication -All:$true
    #$ThirsPartyApps = Get-AzureADServicePrincipal -All:$true | Where-Object { $_.Tags -eq 'WindowsAzureActiveDirectoryIntegratedApp' }
    $Apps = $FirstPartyApps + $ThirsPartyApps
    $Apps | Select-Object DisplayName, AppID, PublicClient, AvailableToOtherTenants, HomePage, LogoutUrl  | Export-Csv "C:\Scripts\AzureADApps.csv"  -NoTypeInformation -Encoding UTF8
}

