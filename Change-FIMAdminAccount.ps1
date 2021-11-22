
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
#   Author: Unkown - Please contact for acknowledgments                     #  
#   Version 0.1         Date Last Modified: 05 November 2010                #  
#                                                                           #  
#############################################################################  
#>

##------------------
#
#
# Usage: .\Change-FIMAdminAccount.ps1 -gMSAAccountName "gmsaAccountName" -AccountName "nameInPortal" -Domain "newdomain" 
#
#
##------------------
PARAM([string]$AccountName, [string]$Domain)
cls
#------------------------------------------------------------------------------------------------------
set-variable -name URI    -value "http://localhost:5725/resourcemanagementservice"    -option constant
 
function GetSidAsBase64 {
    PARAM($gMSAAccountName, $AccountName, $Domain)
    END {
        $sidArray = [System.Convert]::FromBase64String("AQUAAAAAAAUVAAAA71I1JzEyxT2s9UYraQQAAA==") # This sid is a random value to allocate the byte array
        $args = (, $Domain)
        $args += $AccountName
        $ntaccount = New-Object System.Security.Principal.NTAccount $args
        $desiredSid = $ntaccount.Translate([System.Security.Principal.SecurityIdentifier])
        write-host " -Account SID : ($Domain\$AccountName) $desiredSid"
        $desiredSid.GetBinaryForm($sidArray, 0)
        $desiredSidString = [System.Convert]::ToBase64String($sidArray)
        $desiredSidString
    }
}
#------------------------------------------------------------------------------------------------------
write-host "`nFix Account ObjectSID"
write-host "=========================="
#------------------------------------------------------------------------------------------------------
#Retrieve the Base64 encoded SID for the referenced user
$accountSid = GetSidAsBase64 $gMSAAccountName $Domain
#------------------------------------------------------------------------------------------------------
#Export the account configuration from the service:
write-host " -Reading Account information"
if (@(get-pssnapin | where-object { $_.Name -eq "FIMAutomation" } ).count -eq 0) 
{ add-pssnapin FIMAutomation }
 
$exportObject = export-fimconfig -uri $URI `
    -onlyBaseResources `
    -customconfig ("/Person[AccountName='$AccountName']")
if ($exportObject -eq $null) { throw "Cannot find an account by that name" } 
$objectSID = $exportObject.ResourceManagementObject.ResourceManagementAttributes | `
    Where-Object { $_.AttributeName -eq "ObjectSID" }

Write-Host " -New Value = $accountSid"
Write-Host " -Old Value =" $objectSID.Value
 
if ($accountSid -eq $objectSID.Value) {
    Write-Host "Existing value is correct!"
}
else {
    $importChange = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange
    $importChange.Operation = 1
    $importChange.AttributeName = "ObjectSID"
    $importChange.AttributeValue = $accountSid
    $importChange.FullyResolved = 1
    $importChange.Locale = "Invariant"
    $importObject = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject
    $importObject.ObjectType = $exportObject.ResourceManagementObject.ObjectType
    $importObject.TargetObjectIdentifier = $exportObject.ResourceManagementObject.ObjectIdentifier
    $importObject.SourceObjectIdentifier = $exportObject.ResourceManagementObject.ObjectIdentifier
    $importObject.State = 1 
    $importObject.Changes = (, $importChange)
    write-host " -Writing Account information ObjectSID = $accountSid"
    $importObject | Import-FIMConfig -uri $URI -ErrorVariable Err -ErrorAction SilentlyContinue
    if ($Err) { throw $Err }
    Write-Host "Success!"
}
#------------------------------------------------------------------------------------------------------
trap { 
    Write-Host "`nError: $($_.Exception.Message)`n" -foregroundcolor white -backgroundcolor darkred
    Exit
}
#----------------------