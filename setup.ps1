$adminCheck = [Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544'

if (-not $adminCheck) {
    # Relaunch PowerShell as Administrator
    Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy Bypass" , "-Command", $MyInvocation.MyCommand.Definition -Verb RunAs
    return
}

function Confirm-Action {
    param (
        [string]$Message
    )
    $confirmation = Read-Host "$Message (y/n)"
    if ($confirmation -eq 'y') {
        return $true
    }
    else {
        return $false
    }
}


# $destinationPath = "C:\setups"
# $exeFiles = Get-ChildItem -Path $destinationPath -Filter *.exe

# foreach ($exe in $exeFiles) {
#     Start-Process -FilePath $exe.FullName -NoNewWindow 
# }


# $arch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
# if ($arch -match "64") {
#     Start-Process -FilePath "C:\Windows\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -NoNewWindow -Wait
# }
# else {
#     Start-Process -FilePath "C:\Windows\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -NoNewWindow -Wait
# }

Remove-Item -Recurse -Force "$env:PROGRAMDATA\Microsoft OneDrive" 



$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
if (-Not (Test-Path -Path $regPath)) {
    New-Item -Path $regPath -Force
}
New-ItemProperty -Path $regPath -Name "EnableFeeds" -Value 0 -PropertyType DWord -Force

New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_NotifyMoreTiles" -Value 0 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoStartMenuMorePrograms" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoStartMenuSuggestions" -Value 1 -PropertyType DWord -Force

$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
if (-Not (Test-Path -Path $regPath)) {
    New-Item -Path $regPath -Force
}
New-ItemProperty -Path $regPath -Name "NoChangeStartMenu" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path $regPath -Name "HideAppList" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path $regPath -Name "HideRecentlyAddedApps" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path $regPath -Name "NoInstrumentation" -Value 1 -PropertyType DWord -Force

$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\CloudContent"
if (-Not (Test-Path -Path $regPath)) {
    New-Item -Path $regPath -Force
}
New-ItemProperty -Path $regPath -Name "DisableWindowsConsumerFeatures" -Value 1 -PropertyType DWord -Force


$studentUsername = "Student"
$studentSID = (Get-LocalUser $studentUsername).SID

$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"
if (-Not (Test-Path -Path $regPath)) {
    New-Item -Path $regPath -Force
}
New-ItemProperty -Path $regPath -Name "DisableMSI" -Value 1 -PropertyType DWord -Force

$regKey = "Microsoft.PowerShell.Core\Registry::HKEY_USERS\$($studentSID)\Software\Microsoft\Windows\CurrentVersion\Policies"
New-Item -Path "$regKey\Uninstall" -Force
New-Item -Path "$regKey\Explorer" -Force
New-ItemProperty -Path "$regKey\Uninstall" -Name "NoAddRemovePrograms" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "$regKey\Explorer" -Name "NoWindowsUpdate" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "$regKey\Explorer" -Name "NoControlPanel" -Value 1 -PropertyType DWord -Force


#Remove Edge
# Get all user profiles from C:\Users
$userProfiles = Get-ChildItem "C:\Users" -Directory | Where-Object { 
    $_.Name -notin @('All Users', 'Default', 'Default User', 'Public') 
}
# Iterate through each user's desktop folder
foreach ($profile in $userProfiles) {
    $name = $profile.name
    $fullname = $profile.FullName
    $desktopPath = "$fullname\Desktop"
  
    
    Remove-Item -Path "$fullname\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*" -Force -Recurse 
  
    if (Test-Path $desktopPath) {
        # Remove all .lnk (shortcut) files
        Remove-Item "$desktopPath\*.lnk" -Force -ErrorAction SilentlyContinue
    }
}
$profiles = @('Admin', 'Student')
foreach ($p in $profiles) {
    $SID = (Get-LocalUser $p).SID
    $path = "Microsoft.PowerShell.Core\Registry::HKEY_USERS\$($SID)\Software\Microsoft\Windows\CurrentVersion"
    Remove-Item -Path "HKU\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Force -Recurse 
    New-Item -Path "HKU\$($SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force
    New-Item -Path "HKU\$($SID)\Software\Microsoft\Windows\CurrentVersion\Search" -Force
    New-Item -Path "HKU\$($SID)\Software\Microsoft\Windows\CurrentVersion\Feeds" -Force
    New-ItemProperty -Path "$path\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -PropertyType DWord -Force
    New-ItemProperty -Path "$path\Search" -Name "ShowCortanaButton" -Value 0 -PropertyType DWord -Force
    Set-ItemProperty -Path "$path\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value 2 -PropertyType DWord -Force
    
}
# Remove shortcuts from the Public Desktop
$publicDesktopPath = "C:\Users\Public\Desktop"
if (Test-Path $publicDesktopPath) {
    Remove-Item "$publicDesktopPath\*.lnk" -Force -ErrorAction SilentlyContinue
}

Write-Host "Desktop shortcuts removed for all users."


# Stop-Process -ProcessName explorer -Force
# Start-Process explorer


if (Confirm-Action "Explorer lagging? Restart Computer") {
    Restart-Computer -Force
}


Read-Host
