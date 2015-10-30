Start-Transcript -path "C:\ADModifyTranscript.txt" -Append

Import-Module ActiveDirectory

Import-CSV C:\groupNoMail.csv | % {


echo $_.Group
echo $_.Email

$mail = $_.Email

get-adgroup -Identity $_.Group | % {Set-adgroup -Identity $_ -Add @{'mail' = $mail}}

    
    
	}

	
Stop-Transcript	