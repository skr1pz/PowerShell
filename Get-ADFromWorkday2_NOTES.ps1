#$path = Split-Path -parent $MyInvocation.MyCommand.Definition

#$ErrorActionPreference="SilentlyContinue"
#Stop-Transcript | out-null
#$ErrorActionPreference = "Continue"
#Start-Transcript -path ".\ADModifyTranscript.txt" -append



Import-Module ActiveDirectory
#$workday = Import-CSV -Path \\Natasha\root\home\MDMAYER01\UHSEMPS.csv
#$workday = Import-CSV -Path \\iUHSPRD1\root\vendors\workday\UHSEMPS.csv
$workday = Import-CSV -Path C:\users\MDMAYER01\uhsemps.csv
foreach ($line in $workday) {
    
    $logfile = ".\ErrorLog.txt"

    $output = "User: " + $line.Full_Name + $line.Employee_ID

    #Parsed columns in UHSEMPS.csv
    #(Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name'[0])
    #If ($line.$_ -eq ""){$line.$_ = " "}   
    #If (-not $line.Cell_Phone) {$line.Cell_Phone = " "}
    #If (-not $line.Middle_Name) {$line.Middle_Name = $null}

    
    $line | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name' | foreach {If(-not $line.$_){$line.$_ = $null}}
    
    $business_Unit   = $line.Business_Unit
    $cell_Phone      = $line.Cell_Phone
    $company         = $line.Company
    $department      = $line.Department
    $district        = $line.District
    $email           = $line.Email
    $employee_ID     = $line.Employee_ID
    $employee_Status = $line.Employee_Status
    $first_Name      = $line.First_Name
    $full_Name       = $line.Full_Name
    $job_Code        = $line.Job_Code
    $job_Family      = $line.Job_Family
    $job_Title       = $line.Job_Title
    $last_Name       = $line.Last_Name
    $manager_ID      = $line.Manager_ID
    $middle_Name     = $line.Middle_Name
    $work_Phone      = $line.Work_Phone
    
    
    #Take action if employee shows a status of "A" (Active) in UHSEMPS.csv
    If ($employee_Status -eq 'A' -or $employee_Status -eq 'L') {

    
    Try {
    #Parses Full_Name from UHSEMPS.csv which does not have a space after the comma, and inserts one into the $fullName variable
    #$full_Name = $line.Full_Name 
    #$fn = [regex]::Replace($fn, "(^.+?)(,)(\s)(.+$)", '$4 $1');
    $full_Name = $full_Name.replace(",", ", ")
    echo $full_Name
    } Catch {}

     Try{
    #Strip all non numeric characters
    $work_Phone = $work_Phone -replace "\D"
    #If the stripped lenth of numbers equals 10 then format the phone number, if not then keep the formatting from Workday
    If ($work_Phone.length -eq 10){
    $work_Phone = "{0:(###)###-####}" -f ([int64]$work_Phone)
    } else {
    $work_Phone = $line.Work_Phone}
    #$work_Phone = "{0:(###)###-#### x #####}" -f ([int64]$work_Phone)}
    echo $work_Phone
    } Catch {}

    Try {
    #Parses Full_Name from UHSEMPS.csv, splits the string into an array on the comma, discards the comma, organizes the array properly adding "CN=" and ",O=UHS" then removes the period i.e.:"Birkholz,Gary L." becomes this "CN=Gary L Birkholz,O=UHS"; which is used for LTPA token passing
    $dn = $line.Full_Name.Split(",")
    #Write-Output "CN=$($dn[1]) $($dn[0]),O=UHS"
    $dn = "CN=$($dn[1]) $($dn[0]),O=UHS"
    $dn = $dn.replace(".","")
    echo $dn
    } Catch {}

    Try {
    #$middle_Name = $middle_Name.Replace(".","")
    $middle_Name = $middle_Name.Substring(0,1)
    echo $middle_Name
    } Catch {}

    Try {
    $manager_ID = Get-ADUser -Filter {employeeID -eq $manager_ID} -Properties * | Select -ExpandProperty distinguishedName # | Out-String
    #$manager_ID | Format-List *
    #$manager_ID = $manager_ID.Substring(386,48)
    #$manager_ID | Measure-Object -Character
    echo $manager_ID
    $manager_ID.GetType()
    } Catch {}
    

    #User email identifier for pulling from a local copy, local copies have zeros trimmed
    Get-ADUser -Filter {emailaddress -eq $email} | Set-ADUser `
    `
    -DisplayName $full_Name `
    -GivenName $first_Name `
    -Initials $middle_Name `
    -Surname $last_Name `
    -EmailAddress $email `
    -OfficePhone $work_Phone `
    -MobilePhone $cell_Phone `
    -Office $district `
    -Department $department `
    -Title $job_Code `
    -Description $job_Title `
    -Company $company `
    -Manager $manager_ID `
    <# -Add @{'altSecurityIdentities'=$dn} -Replace @{

    'displayName'                = $full_Name;
    'givenName'                  = $first_Name;
    'initials'                   = $middle_Name;
    'sn'                         = $last_Name;
    'mail'                       = $email;
    'telephoneNumber'            = $work_Phone;
    'mobile'                     = $cell_Phone;
    'physicalDeliveryOfficeName' = $district;
    'department'                 = $department;
    'title'                      = $job_Code;
    'description'                = $job_Title;
    'company'                    = $company;
    'manager'                    = $manager_ID
    } #>
    
    #$output + " update failed: " + $error[0].ToString() | Out-File $logfile -append

    }
             
  }



#Rename-Item $logfile "$logfile + $(get-date -Format yyyy-MM-dd)"
#Rename-Item ".\ADModifyTranscript.txt" $(get-date -Format yyyy-MM-dd) + "\ADModifyTranscript.txt"
#Stop-Transcript


