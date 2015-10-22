

Import-Module ActiveDirectory
$csv = Import-Csv c:\IdFix.csv
foreach ($line in $csv) {
    $sam = $line.user
    Remove-ADUser $sam -Confirm:$false
      
}



