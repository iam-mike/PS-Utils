# Re-run command to disable AD Sync after removal of AAD 
# DO NOT USE ON PRODUCTION SYSTEMS

while ((Get-MSOLCompanyInformation).DirectorySynchronizationEnabled) {
    Set-MsolDirSyncEnabled -EnableDirSync $False -Force
    Start-Sleep -Seconds 3600 # Hourly
}