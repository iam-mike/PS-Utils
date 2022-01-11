
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
#   Version 0.1         Date Last Modified: 05 November 2020                #  
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
Clear-Host
#------------------------------------------------------------------------------------------------------
Set-Variable -Name URI -Value 'http://localhost:5725/resourcemanagementservice' -Option constant
 
function GetSidAsBase64 {
    PARAM($gMSAAccountName, $AccountName, $Domain)
    END {
        $sidArray = [System.Convert]::FromBase64String('AQUAAAAAAAUVAAAA71I1JzEyxT2s9UYraQQAAA==') # This sid is a random value to allocate the byte array
        $args = (, $Domain)
        $args += $AccountName
        $ntaccount = New-Object System.Security.Principal.NTAccount $args
        $desiredSid = $ntaccount.Translate([System.Security.Principal.SecurityIdentifier])
        Write-Host " -Account SID : ($Domain\$AccountName) $desiredSid"
        $desiredSid.GetBinaryForm($sidArray, 0)
        $desiredSidString = [System.Convert]::ToBase64String($sidArray)
        $desiredSidString
    }
}
#------------------------------------------------------------------------------------------------------
Write-Host "`nFix Account ObjectSID"
Write-Host '=========================='
#------------------------------------------------------------------------------------------------------
#Retrieve the Base64 encoded SID for the referenced user
$accountSid = GetSidAsBase64 $gMSAAccountName $Domain
#------------------------------------------------------------------------------------------------------
#Export the account configuration from the service:
Write-Host ' -Reading Account information'
if (@(get-pssnapin | Where-Object { $_.Name -eq 'FIMAutomation' } ).count -eq 0) 
{ add-pssnapin FIMAutomation }
 
$exportObject = export-fimconfig -uri $URI `
    -onlyBaseResources `
    -customconfig ("/Person[AccountName='$AccountName']")
if ($null -eq $exportObject) { throw 'Cannot find an account by that name' } 
$objectSID = $exportObject.ResourceManagementObject.ResourceManagementAttributes | `
        Where-Object { $_.AttributeName -eq 'ObjectSID' }

Write-Host " -New Value = $accountSid"
Write-Host ' -Old Value =' $objectSID.Value
 
if ($accountSid -eq $objectSID.Value) {
    Write-Host 'Existing value is correct!'
}
else {
    $importChange = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange
    $importChange.Operation = 1
    $importChange.AttributeName = 'ObjectSID'
    $importChange.AttributeValue = $accountSid
    $importChange.FullyResolved = 1
    $importChange.Locale = 'Invariant'
    $importObject = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject
    $importObject.ObjectType = $exportObject.ResourceManagementObject.ObjectType
    $importObject.TargetObjectIdentifier = $exportObject.ResourceManagementObject.ObjectIdentifier
    $importObject.SourceObjectIdentifier = $exportObject.ResourceManagementObject.ObjectIdentifier
    $importObject.State = 1 
    $importObject.Changes = (, $importChange)
    Write-Host " -Writing Account information ObjectSID = $accountSid"
    $importObject | Import-FIMConfig -uri $URI -ErrorVariable Err -ErrorAction SilentlyContinue
    if ($Err) { throw $Err }
    Write-Host 'Success!'
}
#------------------------------------------------------------------------------------------------------
trap { 
    Write-Host "`nError: $($_.Exception.Message)`n" -ForegroundColor white -BackgroundColor darkred
    Exit
}
#------------------------------------------------------------------------------------------------------