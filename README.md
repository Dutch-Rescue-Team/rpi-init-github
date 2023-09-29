# rpi-init-GitHub


 ## Goal
 
 This tool is created to provide easy access to the git repos of the Dutch Rescue Team on GitHub from the Raspberry Pi for the team members who already have access to these repos from their Windows computer.

## Concept

### User experience
For each SD card used for the operating system in the Raspberry Pi an ssh-key will be generated for access to GitHub.
Setting up the access to GitHub on the Raspberry Pi will be done from the Windows development workstation.
The rpi-init-GitHub.ps1 PowerShell script takes care of this using the local git and GitHub settings.

### Entry criteria
* A developer using Windows to develop for the Dutch Rescue Team.
* This developer has already access to the Dutch Rescue Team git repos on GitHub.

## Prepare Windows development workstation

* For the commands shown an elevated PowerShell is used.
* Use a passphrase when requested for the private key and keep this passphrase in a password safe.

| Action | Command (with example values)
| --- | --- 
| Enable the OpenSSH Client optional service. | 
| Check that Windows included OpenSSH is used. (Expected: C:\Windows\System32\OpenSSH\ssh.exe) | Get-Command ssh
| Install and configure SSH-Agent service. | Get-Service ssh-agent \| Set-Service -StartupType Automatic -PassThru \| Start-Service
| Generate SSH Key Pair. | ssh-keygen -t ed25519 -C "your@mailaddress.tech @GitHub from pcname 230810" -f $HOME/.ssh/your@mailaddress.tech@GitHub__pcname__230810_id
| Get the public key. | cat $HOME/.ssh/your@mailaddress.tech@GitHub__pcname__230810_id.pub
| Add the public key to your GitHub account as a new SSH Key for authentication. | https://GitHub.com/settings/keys
| Test connection with GitHub using ssh. | ssh -i $HOME/.ssh/your@mailaddress.tech@GitHub__pcname__230810_id -T git@GitHub.com
| Allow using key without password, by storing the key in the SSH Agent. | ssh-add $HOME/.ssh/your@mailaddress.tech@GitHub__pcname__230810_id
| <p>Allow connecting using 'ssh drt@drtbot' by adding something like this to $HOME/.ssh/config. <br>NOTE: Because we often refresh our SD cards with the latest DRT image, the ECDSA host key often changes causing ssh to reject the connection by default until this host key is added to known_hosts. In this example the option has been chosen to reduce security by setting 'StrictHostKeyChecking no' to ease usage.</p> | <p># Used to login to bash as drt on drt* <br>Host drt* <br>&nbsp;&nbsp;&nbsp;&nbsp;StrictHostKeyChecking no <br>&nbsp;&nbsp;&nbsp;&nbsp;User drt <br>&nbsp;&nbsp;&nbsp;&nbsp;IdentityFile ~/.ssh/drt@drtbot__yourname_230722_rsa_id <br> <br># Overall defaults <br>Host * <br>&nbsp;&nbsp;&nbsp;&nbsp;AddKeysToAgent yes <br>&nbsp;&nbsp;&nbsp;&nbsp;IdentitiesOnly yes <br>&nbsp;&nbsp;&nbsp;&nbsp;Protocol 2 <br>&nbsp;&nbsp;&nbsp;&nbsp;Port 22 <br></p>
| Download and install the latest version of GitHub CLI. | https://cli.GitHub.com/
| <p>Allow using GitHub CLI passwordless, by authorizing as Authorized OAuth App with GitHub, by:<br><ul><li>executing the command, </li><li>skipping uploading your public key because you've done that already </li><li>and further follow instructions.</li></ul></p> | gh auth login --hostname GitHub.com --git-protocol ssh --web --scopes admin:public_key

## Prepare Raspberry Pi

* The SD card images used by the Dutch Rescue Team come with this preparation done.

| Action | Command
| --- | --- 
| <p>Make sure package 'expect' is installed (https://jestjs.io/docs/expect).<br>This is used to run interactive commands headless.</p> | sudo apt-get install expect
| <p>Make sure package 'pwgen' is installed (https://linux.die.net/man/1/pwgen).<br>This is used to generate the passphrase used in the generation of the ssh key.</p> | sudo apt-get install pwgen

## Usage
```powershell
rpi-init-GitHub.ps1 [-RpiSshUserAtHost] <string> [[-GitHubOwnerSlashRepo] <string>] [-NoPassphrase]
```

| Parameter | Function
| --- | ---
| RpiSshUserAtHost | <p>Provide \<user>@\<host> to be used in the ssh connections to the Rapberry Pi.<br>E.g. drt@drtbot</p>
| GitHubOwnerSlashRepo | <p>Provide \<owner>/\<repo> of the GitHub repository to be cloned to the Raspberry Pi ~/src/\<repo> directory.<br>E.g. Dutch-Rescue-Team/drtbot</p>
| NoPassphrase |  <p>Switch to force creating the private key on the Raspberry Pi without a passphrase.<br>Notes:<br><ul><li>When using a passphrase, make sure to keep the value secure in a password safe.</li><li>When not using a passphrase anyone who manages to get your private key file will have access to your GitHub account authenticating as you.</li></ul></p>
