# check-time.ps1
# Simple helper script to check time sync on Domain Controller / Client

Write-Host "==== Checking System Time and Time Source ====" -ForegroundColor Cyan

# Show local system time
Get-Date | Format-List

# Show time configuration (NTP, source, sync status)
w32tm /query /status

# Show current time sources
w32tm /query /source
w32tm /query /peers

Write-Host "`nIf your time differs by more than 5 minutes, Kerberos authentication and SSO may fail." -ForegroundColor Yellow
