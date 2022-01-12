function StartConnection {
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
        }
        elseif (Get-Module -ListAvailable -Name AzureADPreview) {
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
}
StartConnection
$GetUPN = Read-Host 'Enter the UPN of the user you want to search:' -ForegroundColor Yellow
$UPN = (Get-AzureADUser -Filter "userPrincipalName eq '${GetUPN}'").userPrincipalName
$LastLogin = Get-AzureAdAuditSigninLogs -top 1 -filter "userprincipalname eq '${UPN}'" | Select-Object CreatedDateTime
Return $LastLogin