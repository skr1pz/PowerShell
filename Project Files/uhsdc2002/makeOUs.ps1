<#
	Program: makeOUs.ps1
	Author : Mark Mayer 05929
	Created: 20150826
	Queries user Office field in AD and creates the OU if it does not exist, it creates UHS OUs if the number is less than 300, and creates the OU if equal to or greater than 300
#>

#Sets up transactional logging
Remove-Item ".\makeOU.txt"
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path ".\makeOU.txt" -Append



Import-Module ActiveDirectory

$OU = @('OU=UHS Users,DC=int,DC=uhs,DC=com','OU=UHSSS Users,DC=int,DC=uhs,DC=com')




$OU | % {Get-ADUser -Filter {(enabled -eq "True")} -SearchBase $_ -Properties *} | ? {$_.Office -notlike "Dist*" -and $_.Office -notlike $null} | % {
	

          
echo $_.Office

			If (!([adsi]::Exists("LDAP://OU=District $($_.Office),OU=UHS Users,DC=int,DC=uhs,DC=com")) -and ($_.Office -lt "300" -or $_.Office -eq "801")) {
			
			    Try {
			
				    New-ADOrganizationalUnit -Name "District $($_.Office)" -Path "OU=UHS Users,DC=int,DC=uhs,DC=com"

			        } Catch {}
				
		        }
                
				ElseIf (!([adsi]::Exists("LDAP://OU=District $($_.Office),OU=UHSSS Users,DC=int,DC=uhs,DC=com")) -and ($_.Office -ge "300")) {

                        Try {
				
					        New-ADOrganizationalUnit -Name "District $($_.Office)" -Path "OU=UHSSS Users,DC=int,DC=uhs,DC=com"

					        } Catch {}
					
				        }
				
				        Else {}

            }
					
			
					
Stop-Transcript					