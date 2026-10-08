# PowerShell scripts used to build the lab
# to make OU and users in Powershell Script.
New-ADOrganizationalUnit -Name "SomTech" -Path "DC=somtech,DC=com"
"IT","HR","Finance","Workstations","Servers" | ForEach-Object {
  New-ADOrganizationalUnit -Name $_ -Path "OU=SomTech,DC=somtech,DC=com"
}

New-ADUser -Name "Fullname" -SamAccountName "username" -UserPrincipalName "username@somtech.com" `
  -Path "OU=HR,OU=SomTech,DC=somtech,DC=com" `
  -AccountPassword (Read-Host -AsSecureString "Password") -Enabled $true
