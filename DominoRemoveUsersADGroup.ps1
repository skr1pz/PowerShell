Start-Transcript -path "C:\ADModifyTranscript.txt" -Append

Import-Module ActiveDirectory

Import-CSV C:\DominoGroupMembers.csv | % {

$line.Group = $_.Group

Get-ADGroupMember -Identity $_.Group | % {Remove-ADGroupMember -Identity $line.Group $_ -Confirm:$false}
    
    
	}

	
Stop-Transcript	