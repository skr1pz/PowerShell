<#
    Name        : Set Employee ID (set-employeeID.ps1)
    Version     : 0.1
    Author      : Mark Mayer
    Description : Script to import employee number attribute, export AD and Lotus info, perform SQL join for missing data and import data feeding from CSV file - can import any attribute i.e. mail - also this will over write data.
#>


$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\output.txt -append




Import-Module ActiveDirectory
$csv = Import-Csv c:\users\mdmayer01\sAM_format_table.csv
foreach ($line in $csv) {
    $sam = $line.sAMAccountName
    Get-ADUser -Filter {sAMAccountName -eq $sam} | 
        Set-ADUser -OfficePhone $line.mail
}



Stop-Transcript