# rpi-init-github.ps1
Param (
  # Provide <user>@<host> to be used in the ssh connections to the Rapberry Pi.
  [Parameter(Mandatory)]
  [string] $RpiSshUserAtHost = "drt@drtbot",
  # Provide <owner>/<repo> of the GitHub repository to be cloned to the Raspberry Pi ~/src/<repo> directory.
  [string] $GitHubOwnerSlashRepo = "Dutch-Rescue-Team/drtbot",
  # Switch to force creating the private key on the Raspberry Pi without a passphrase.
  [switch] $NoPassphrase
)
# Write-Host "The value of `$RpiSshUserAtHost is: $RpiSshUserAtHost"
# Write-Host "The value of `$NoPassphrase is: $NoPassphrase"
# Write-Host "The value of `$PSScriptRoot is: $PSScriptRoot"

$ErrorActionPreference = "Stop"

###
# Test ssh connection to RPi.
Write-Host "Test ssh connection to RPi."
ssh -q $RpiSshUserAtHost exit
If ($LASTEXITCODE -ne 0)
{
  Throw "Can't connect to $RpiSshUserAtHost."
}

###
# Capture git config from local host.
Write-Host "Capture git config from local host."
$GitUserName = git config user.name
$GitUserEmail = git config user.email
# Write-Host "The value of `$GitUserName is: $GitUserName"
# Write-Host "The value of `$GitUserEmail is: $GitUserEmail"

###
# Transfer bash script to RPi.
Write-Host "Transfer bash script to RPi."
scp -q "$PSScriptRoot\rpi-init-github.sh" "${RpiSshUserAtHost}:."
ssh -q $RpiSshUserAtHost "chmod +x rpi-init-github.sh"

###
# Run init on RPi.
Write-Host "Run init on RPi."
$Feedback = ssh -q $RpiSshUserAtHost "./rpi-init-github.sh init """"$GitUserName"""" $GitUserEmail $NoPassphrase | tee rpi-init-github.log" | Select-String -Pattern "^FEEDBACK\["
# Write-Host "The value of `$Feedback is: $Feedback"
$PublicKeyLine = echo $Feedback | Select-String -Pattern "^FEEDBACK\[PUBLIC KEY]: "
$PublicKey = $PublicKeyLine.Tostring().Substring(22)
# Write-Host "The value of `$PublicKey is: $PublicKey"
$KeyTitleLine = echo $Feedback | Select-String -Pattern "^FEEDBACK\[KEY TITLE]: "
$KeyTitle = $KeyTitleLine.Tostring().Substring(21)
# Write-Host "The value of `$KeyTitle is: $KeyTitle"
$PassphraseLine = echo $Feedback | Select-String -Pattern "^FEEDBACK\[PASSPHRASE]: "
$Passphrase = $PassphraseLine.Tostring().Substring(22)
# Write-Host "The value of `$Passphrase is: $Passphrase"
$SshCfgDoneLine = echo $Feedback | Select-String -Pattern "^FEEDBACK\[SSH CONFIG DONE]: "
$SshCfgDone = $SshCfgDoneLine.Tostring().Substring(27)
# Write-Host "The value of `$SshCfgDone is: $SshCfgDone"
$NormalEnd = echo $Feedback | Select-String -Pattern "^FEEDBACK\[NORMAL END]"
If ("$NormalEnd" -eq "")
{
  Throw "Init on RPi failed."
}

###
# Remove superseded keys (= same title) from GitHub.
Write-Host "Remove superseded keys from GitHub."
$SameTitleList = gh ssh-key list | Select-String -Pattern "^$KeyTitle\s"
$KeyIdList = echo $SameTitleList | foreach { ($_ -split '\s+')[4] }
# Write-Host "The value of `$SameTitleList is: $SameTitleList"
# Write-Host "The value of `$KeyIdList is: $KeyIdList"
foreach ($KeyId in $KeyIdList)
{
  # Write-Host "The value of `$KeyId is: $KeyId"
  gh ssh-key delete $KeyId -y
}

###
# Add new authentication key to GitHub.
Write-Host "Add new authentication key to GitHub."
echo "$PublicKey" | gh ssh-key add --type authentication --title "$KeyTitle"

###
# Clone repo to RPi.
Write-Host "Clone repo to RPi."
$Feedback = ssh -q $RpiSshUserAtHost "./rpi-init-github.sh clone """"$GitHubOwnerSlashRepo"""" $Passphrase | tee -a rpi-init-github.log" | Select-String -Pattern "^FEEDBACK\["
# Write-Host "The value of `$Feedback is: $Feedback"
$NormalEnd = echo $Feedback | Select-String -Pattern "^FEEDBACK\[NORMAL END]"
If ("$NormalEnd" -eq "")
{
  Throw "Clone on RPi failed."
}

###
# THE END
Write-Host ""
If ($SshCfgDone -ne "True")
{
  Write-Host "WARNING: Ssh config file has not been created (probably already existed)."
}
Write-Host "NOTE PASSPHRASE: $Passphrase"
Write-Host ""
cmd /c 'pause'
