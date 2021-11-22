
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
#   Version 0.1         Date Last Modified: 05 November 2021                #  
#                                                                           #  
#############################################################################  
#>


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

