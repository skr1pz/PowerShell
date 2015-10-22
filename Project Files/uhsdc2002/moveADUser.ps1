<#
	Program: moveADUser.ps1
	Author : Mark Mayer 05929
	Created: 20150826
	Moves users to their appropriate OU
#>

#Sets up transactional logging
Remove-Item ".\moveADUser.txt"
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path ".\moveADUser.txt" -Append



Import-Module ActiveDirectory

#Set searchbase
$OU = @('OU=UHS Users,DC=int,DC=uhs,DC=com','OU=UHSSS Users,DC=int,DC=uhs,DC=com')


$OU | % {Get-ADUser -Filter {(enabled -eq "True")} -SearchBase $_ -Properties *} | ? {$_.Office -notlike "Dist*" -and $_.Office -notlike $null} | % {
echo $_.Office

If (($_.Office -lt "300") -or ($_.Office -eq "801")) {

	Try {
	
		Move-ADObject -Identity $_.ObjectGUID -TargetPath "OU=District $($_.Office),OU=UHS Users,DC=int,DC=uhs,DC=com"
		
		} Catch {}
		
	}
		
	ElseIf ($_.Office -ge "300") {
	
		Try {
		
			Move-ADObject -Identity $_.ObjectGUID -TargetPath "OU=District $($_.Office),OU=UHSSS Users,DC=int,DC=uhs,DC=com"
			
			} Catch {}
			
	}
			
				Else {}
				
	
}					
			
					
Stop-Transcript					