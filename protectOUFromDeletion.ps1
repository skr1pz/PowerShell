<# 
   Sets flag to "Protect from accidental deletion on all OUs in Searchbase of $OU variable
   By: Mark Mayer
   On: 20150824
 #>   

Import-Module ActiveDirectory
$OU = @('OU=UHS Users,DC=int,DC=uhs,DC=com','OU=UHSSS Users,DC=int,DC=uhs,DC=com','OU=UHS Computers,DC=int,DC=uhs,DC=com','OU=UHSSS Computers,DC=int,DC=uhs,DC=com')
$OU | % {Get-ADOrganizationalUnit -filter * -Searchbase $_ | Set-ADObject -ProtectedFromAccidentalDeletion:$true}