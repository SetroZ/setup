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


Write-Host "Connecting to wifi"
netsh wlan add profile filename="D:\setups\scripts\profile.xml"
netsh wlan connect name="Ramsden Students"

Write-Host "Connected To Ramsden Wifi"

Write-Host "Setup users"
$newUsername = "Admin"
$newPassword = "je1234"

$currentUsername = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName).Split('\')[-1]

Rename-LocalUser -Name $currentUsername -NewName $newUsername

Set-LocalUser -Name $newUsername -Password (ConvertTo-SecureString $newPassword -AsPlainText -Force)
Write-Host "User renamed to '$newUsername' and password updated successfully."

$studentUsername = "Student"
$studentPassword = "codingisfun"

New-LocalUser -Name $studentUsername -Password (ConvertTo-SecureString $studentPassword -AsPlainText -Force) -PasswordNeverExpires -Description "Student User"
Add-LocalGroupMember -Group "Users" -Member $studentUsername
Set-LocalUser -Name $studentUsername -PasswordNeverExpires $true
Write-Host "Users created successfully!"
# psexec.exe -u Student -p codingisfun cmd.exe \c exit


$ParentDirectory = Split-Path -Path $PSScriptRoot -Parent
if (Confirm-Action "Copy Files to C:\setups") {
    $Destination = "C:\setups"
    Copy-Item -Path $ParentDirectory -Destination $Destination -Recurse
    Write-Host "Copied"
    $scriptPath = "C:\setup\scripts\setup.ps1"
    # Start a new PowerShell process with elevated privileges
    Start-Process powershell -ArgumentList "-NoExit", "-File", $scriptPath -Verb RunAs
}


Read-Host 





