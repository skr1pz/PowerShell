

Import-Module ActiveDirectory
$csv = Import-Csv c:\inMoNumb.csv
foreach ($line in $csv) {
    $sam = $line.Emp
    Get-ADUser -Filter {(employeeID -eq $sam) -and (enabled -eq $true)} -Properties * | Select sAMAccountName, EmployeeID, Office | Export-CSV -append .\inMoScanner.csv
      
}



