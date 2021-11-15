#########################################################
#
# Name: Start-mcsPamSyncCycle.ps1
# Version: 1.1
# Date: 08/12/2019
# Comment: Script to execute a Full or Delta sync cycle for
#          MCS PAM solution.  
# Version: Added flag to clear run history
#
#########################################################

Param(
    [ValidateSet("Full","Delta")]
    [String]$Type,
    [Switch]$ClearRunHistory,
    [Timespan]$DurationToRetain
)


#Variables
$MAs = Get-WmiObject -Class "MIIS_ManagementAgent" -Namespace "root\MicrosoftIdentityIntegrationServer"
$CorpADMA = $MAs | ?{$_.Name -eq "Corp AD MA"}
$MIMMA = $MAs | ?{$_.Name -eq "MIM Service MA"}
$DefaultDuration = New-TimeSpan -Days 14

if (!$DurationToRetain -or ($DurationToRetain -lt (New-TimeSpan -Days 0))) {
    $DurationToRetain = $DefaultDuration
}

#region Functions
function Run-ManagementAgent {
    Param (
        $MA,
        [ValidateSet("DI","DS","E","FI","FS")]
        $Profile
    )

    $duration = Measure-Command {$result = $MA.Execute("$Profile")}
    Write-Host "Completed $($MA.Name) $Profile.  Duration: $($duration.TotalSeconds) seconds."
    
    if ($result.ReturnValue -eq "success") {
        Write-host -foregroundcolor Green "Result: $($result.ReturnValue)"
    } else {
        Write-Host -ForegroundColor Yellow "Result: $($result.ReturnValue) -- check run history (timestamp $(Get-Date -f yyy.dd.MM.hh:mm:sstt))"
    }
}

function Clear-RunHistory {
    Param([timespan]$DurationToRetain)

    $DeleteDay = (Get-Date).Subtract($DurationToRetain)

     Write-Host "Deleting run history before: " $DeleteDay.toString('MM/dd/yyyy')
     $Server = @(get-wmiobject -class "MIIS_SERVER" -namespace "root\MicrosoftIdentityIntegrationServer" -computer ".") 
     Write-Host "Result: " $Server[0].ClearRuns($DeleteDay.toString('yyyy-MM-dd')).ReturnValue
}
#endregion

#region Main Script
Switch ($Type) {
    Full {
        Run-ManagementAgent -MA $MIMMA -Profile FI
        Run-ManagementAgent -MA $CorpADMA -Profile FI
        Run-ManagementAgent -MA $MIMMA -Profile FS
        Run-ManagementAgent -MA $CorpADMA -Profile FS
        Run-ManagementAgent -MA $MIMMA -Profile E
        Run-ManagementAgent -MA $MIMMA -Profile DI
        Run-ManagementAgent -MA $MIMMA -Profile DS
    }
    Delta {
        Run-ManagementAgent -MA $MIMMA -Profile DI
        Run-ManagementAgent -MA $CorpADMA -Profile DI
        Run-ManagementAgent -MA $MIMMA -Profile DS
        Run-ManagementAgent -MA $CorpADMA -Profile DS
        Run-ManagementAgent -MA $MIMMA -Profile E
        Run-ManagementAgent -MA $MIMMA -Profile DI
        Run-ManagementAgent -MA $MIMMA -Profile DS
    }
}

#Clear Run History
If ($ClearRunHistory) {
    Clear-RunHistory -DurationToRetain $DurationToRetain
}




#endregion

