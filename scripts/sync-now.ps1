\
# sync-now.ps1
# Run as Administrator on the Azure AD Connect server
Import-Module ADSync
Start-ADSyncSyncCycle -PolicyType Delta
Write-Output "Delta sync started at $(Get-Date -Format o)"
