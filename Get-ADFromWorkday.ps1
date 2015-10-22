$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\output.txt -append




Import-Module ActiveDirectory
$workday = Import-CSV -Path \\Natasha\root\home\MDMAYER01\UHSEMPS.csv
foreach ($line in $workday) {
    $email = $line.Email
    Get-ADUser -Filter {emailaddress -Like $email} -Properties sAMAccountName, mail | FT sAMAccountName, mail
              
}

Stop-Transcript

