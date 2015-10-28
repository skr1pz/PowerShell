Start-Transcript -path "C:\ADModifyTranscript.txt" -Append

Import-Module ActiveDirectory


$dominoList = Import-CSV -Path C:\DominoGroups.csv


foreach ($line in $dominoList) {
    
    

    #Parse columns in UHSEMPS.csv to look for blank values and set them to $null        
    $line | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name' | foreach {If(-not $line.$_){$line.$_ = $null}}

    
    #Parsed columns in UHSEMPS.csv 
    $Group          = $line.Group
    $Email          = $line.Email
    $Description    = $line.Company
	$Members        = $line.Members
	
	
	
	Try {

New-ADGroup -Path "OU=Distribution Lists,DC=int,DC=uhs,DC=com" -Name $line.Group -SamAccountName $line.Group -GroupScope Universal -GroupCategory Distribution -Description $line.Description -OtherAttributes -Add @{'mail' = $line.Email}

}

Catch {}
pause
}

Stop-Transcript