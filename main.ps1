# if (Confirm-Action "Delete all users") {
#     # Get all local user accounts except "Admin"
#     $users = Get-LocalUser | Where-Object { $_.Name -ne "Admin" -and $_.Enabled -eq $true }
    
#     foreach ($user in $users) {
#         try {
#             # Remove the user account
#             Remove-LocalUser -Name $user.Name
#             Write-Output "Deleted user account: $($user.Name)"
            
#             # Remove the corresponding user folder
#             $userFolder = Join-Path -Path "C:\Users" -ChildPath $user.Name
#             if (Test-Path -Path $userFolder) {
#                 Remove-Item -Path $userFolder -Recurse -Force
#                 Write-Output "Deleted user folder: $userFolder"
#             }
#             else {
#                 Write-Output "User folder not found: $userFolder"
#             }
#         }
#         catch {
#             Write-Output "Failed to delete user account or folder: $($user.Name) - $_"
#         }
#     }
    
#     # Confirm remaining user accounts
#     Write-Output "Remaining user accounts:"
#     Get-LocalUser
# }

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

# 
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





$ParentDirectory = Split-Path -Path $PSScriptRoot -Parent
if (Confirm-Action "Copy to C:\setups ?") {
    $Destination = "C:\setups"
    Write-Host "Copying....."
    Copy-Item -Path $ParentDirectory -Destination $Destination -Recurse
    Write-Host "Copied"
    # $scriptPath = "C:\setup\scripts\setup.ps1"
    # # Start a new PowerShell process with elevated privileges
    # Start-Process powershell -ArgumentList "-NoExit", "-File", $scriptPath -Verb RunAs
}
Write-Host "Ejecting USB...."
$driveEject = New-Object -comObject Shell.Application
$driveEject.Namespace(17).ParseName("D:\").InvokeVerb("Eject")

Write-Host "Sign in into student and run C:\setups\scripts\setup script"
Read-Host





