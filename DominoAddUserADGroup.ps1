Start-Transcript -path "C:\ADModifyTranscript.txt" -Append

Import-Module ActiveDirectory

Import-CSV C:\DominoGroupMembers.csv | % {


if ($(Get-ADUser $_.Members) -ne $null) {

	Add-ADGroupMember -Identity $_.Group -Members $_.Members
	
	} else {
    $me = $($_.Members + " - DG")
   	Add-ADGroupMember -Identity $_.Group -Members $me
	echo $me	  
    }
		  
    
	echo $_.Group
	echo $_.Members
    
    
	}

	
Stop-Transcript	