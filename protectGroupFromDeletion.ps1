<# 
   Sets flag to "Protect from accidental deletion on all Groups in Searchbase of $OU variable
   By: Mark Mayer
   On: 20150824
 #>   

Import-Module ActiveDirectory
$Groups = @('OU=UHS Groups,DC=int,DC=uhs,DC=com','OU=UHSSS Groups,DC=int,DC=uhs,DC=com')
$Groups | % {Get-ADObject -filter {(ObjectClass -eq "group")} -Searchbase $_ | Set-ADObject -ProtectedFromAccidentalDeletion:$true}