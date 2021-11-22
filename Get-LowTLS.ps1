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
#############################################################################  


#pre-requisites
# 1. Review Microsoft Graph SDK https://docs.microsoft.com/en-us/graph/powershell/installation
# 2. Elevate PowerShell session to Administrator
# 3. Install-Module Microsoft.Graph -Scope AllUsers

$tId = "abcd01e2-fa34-5d67-efab-890c1234d56e" #tenant ID
$agoDays = 4 #will filter the log for $agoDays from current date/time
$startDate = (Get-Date).AddDays(-($agoDays)).ToString('yyyy-MM-dd') #calculate start date for filter
$pathForExport = "./" #path to local filesystem for export of CSV file

Connect-MgGraph -TenantId $tId -Scopes "AuditLog.Read.All" #could also use Directory.Read.All
Select-MgProfile "beta" #Low TLS available in MS Graph preview endpoint
$signInsInteractive = Get-MgAuditLogSignIn -Filter "createdDateTime ge $startDate" -All
$signInsNonInteractive = Get-MgAuditLogSignIn -Filter "createdDateTime ge $startDate and signInEventTypes/any(t: t eq 'nonInteractiveUser')" -All

$signInsInteractive | Foreach-Object {
    foreach ($authDetail in $_.AuthenticationProcessingDetails)
    {
        if(($authDetail.Key -match "Legacy TLS") -and ($authDetail.Value -eq "True")){
            $_ | select CorrelationId, createdDateTime, userPrincipalName, userId, UserDisplayName, AppDisplayName, AppId, IPAddress, isInteractive, ResourceDisplayName, ResourceId 
        }
    }

} | Export-Csv -NoTypeInformation -Path ($pathForExport + "Interactive_lowTls_$tId.csv")

$signInsNonInteractive | Foreach-Object {
    foreach ($authDetail in $_.AuthenticationProcessingDetails)
    {
        if(($authDetail.Key -match "Legacy TLS") -and ($authDetail.Value -eq "True")){
            $_ | select CorrelationId, createdDateTime, userPrincipalName, userId, UserDisplayName, AppDisplayName, AppId, IPAddress, isInteractive, ResourceDisplayName, ResourceId 
        }
    }

} | Export-Csv -NoTypeInformation -Path ($pathForExport + "NonInteractive_lowTls_$tId.csv")
