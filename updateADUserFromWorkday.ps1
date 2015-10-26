<#
Program:      updateADUserFromWorkday.ps1
Author:       Mark Mayer 05929
Date:         September 25th 2015
Description:  Updates AD information from UHSEMPS.csv, which is originated from Workday
Prerequisite: Powershell v3.0 
Update:       Added proxyAddresses field for Exchange support and updated UserPrincialName for Office 365 support
#>

#Checks to see if UAC has an Administrator token and grants one if needed
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

#Set-ExecutionPolicy Bypass

#Sets up transactional logging
Remove-Item ".\ADModifyTranscript.txt"
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path ".\ADModifyTranscript.txt" -Append



Import-Module ActiveDirectory


#Pulls UHSEMPS.csv from the IFS of the iSeries
$workday = Import-CSV -Path \\iUHSPRD1\Root\vendors\workday\UHSEMPS.csv
#$workday = Import-CSV -Path \\uhs61927\c$\users\MDMAYER01\uhsemps.csv

#Deletes the temporary error log from last run
Remove-Item .\ErrorLog.txt


#Parses each line of UHSEMPS.csv
foreach ($line in $workday) {
    
    #Creates logfile for errors
    $logfile = ".\ErrorLog.txt"

    #Grabs user information from UHSEMPS.csv to append to error messages
    $output = "User: " + $line.Full_Name + " " + $line.Email + " " + $line.Employee_ID + " " + $line.Company + " " + $line.District

    #Parse columns in UHSEMPS.csv to look for blank values and set them to $null        
    $line | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name' | foreach {If(-not $line.$_){$line.$_ = $null}}

    
    #Parsed columns in UHSEMPS.csv 
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
    
    
    #Finds user with status of "Active" or "Leave" (leave means that the user is still active so we'll treat it the same)
    #If ($employee_Status -eq 'A' -or $employee_Status -eq 'L') {
	If ($employee_Status -eq 'A') {
    

        Try {

            #Parses Full_Name from UHSEMPS.csv which does not have a space after the comma, and inserts one into the $fullName variable
            $full_Name = $full_Name.replace(",", ", ")
            echo $full_Name
            
            } Catch {}


    
        Try {
        
            #LTPA - Parses Full_Name from UHSEMPS.csv, splits the string into an array on the comma, discards the comma, organizes the array properly adding "CN=" and ",O=UHS" then removes the period i.e.:"Birkholz,Gary L." becomes this "CN=Gary L Birkholz,O=UHS"; which is used for LTPA token passing
            $dn = $line.Full_Name.Split(",")
            $dn = "CN=$($dn[1]) $($dn[0]),O=UHS"
            $dn = $dn.replace(".","")
            echo $dn
            
            } Catch {}


        
        Try {

            #Parses Middle_Name and grabs the first character and excludes everything after i.e. period, full middle name
            $middle_Name = $middle_Name.Substring(0,1)
            echo $middle_Name
            
            } Catch {}

    

        Try {
        
            #Strip all non numeric characters
            $work_Phone = $work_Phone -replace "\D"
                
            #If the stripped lenth of numbers equals 10 then format the phone number, if not then keep the formatting from Workday
            If ($work_Phone.length -eq 10){
                   
                   $work_Phone = "{0:(###) ###-####}" -f ([int64]$work_Phone)
        
            } 
            
             Else {
        
                  $work_Phone = $line.Work_Phone}
                  echo $work_Phone
        
                  } Catch {}


    
        Try {

            #Strip all non numeric characters
            $cell_Phone = $cell_Phone -replace "\D"
        
            #If the stripped lenth of numbers equals 10 then format the phone number, if not then keep the formatting from Workday
            If ($cell_Phone.length -eq 10){
        
                    $cell_Phone = "{0:(###) ###-####}" -f ([int64]$cell_Phone)
        
            } 
            
             Else {

                  $cell_Phone = $line.Cell_Phone}
                  echo $cell_Phone
        
                  } Catch {}


    
        Try {

            #UHSEMPS.csv supplies an employeeID for manager identification, the manager attribute in AD requires a distinguishedName i.e. CN=MDMAYER01,OU=IS Support,DC=int,DC=uhs,DC=com
            $manager_ID = Get-ADUser -Filter {(enabled -eq "True") -and (employeeID -eq $manager_ID)} -Properties * | Select -ExpandProperty distinguishedName
            echo $manager_ID
        
            #Explicitly set manager_ID to $null if there's a wrongly formatted manager_ID number in UHSEMPS.csv
            } Catch {$manager_ID = $null}
    

    
        #Find active Workday employees in AD with populated values from UHSEMPS.csv, disregard terminated employees
        Try {
    
            #Find AD user by employeeID step down to "ElseIf" statement if AD user cannot be found
            If (Get-ADUser -Filter {(enabled -eq "True") -and (employeeID -eq $employee_ID)}) {
    
                #This is the update user function
                $update = {
                Get-ADUser -Filter {(enabled -eq "True") -and (employeeID -eq $employee_ID)} | Set-ADUser `
                `
                -DisplayName         $($first_Name + " " + $last_Name) `
                -GivenName           $first_Name `
                -Initials            $middle_Name `
                -Surname             $last_Name `
                -EmailAddress        $email `
                -OfficePhone         $work_Phone `
                -MobilePhone         $cell_Phone `
                -Office              $district `
                -Department          $department `
                -Title               $job_Title `
                -Description         $job_Title `
                -Company             $company `
                -Manager             $manager_ID `
				-UserPrincipalName   $email `
                `  <# altSecurityIdentities is where the Domino distinguishedName gets stored, adding proxyAddresses for Exchange #> `
                -Add @{'altSecurityIdentities'=$dn;'proxyAddresses'=$("SMTP:" + $email), $("SIP:" + $email)} }
  
                #Invoke update user function
                Invoke-Command $update
                echo "command is invoked"

            }

             #Find AD user by email if user cannot be found by employeeID
             ElseIf (Get-ADUser -Filter {(enabled -eq "True") -and (emailaddress -eq $email)}) {

                    echo "find by email"
                    #Find user and update their employeeID in AD
                    Get-ADUser -Filter {(enabled -eq "True") -and (emailaddress -eq $email)} | Set-ADUser -EmployeeID $employee_ID

                    #Invoke the update user function now that the employeeID is set
                    Invoke-Command $update
                    echo "invoke from email"
             
             }
        
                #If the user cannot be found in AD by either emailAddress or employeeID log the information from UHSEMPS.csv
                Else {

                     $output + " -emailAddress and employeeID are both missing in AD, the AD account is disabled or there is no AD account" | Out-File $logfile -Append
                     echo "emailAddress and employeeID for user not found in AD"

                     }
    

        }
        
            #Log active Workday employees that are missing the employeeID value in UHSEMPS.csv or ultiple enabled users in AD with the same employeeID        
            Catch {
        
                  $output + " value not found in AD or multiple enabled users in AD with the same employeeID: " + $error[0].ToString() | Out-File $logfile -Append
                  echo "Can't read value in UHSEMPS"

                  }
  
     }
#pause
}

Stop-Transcript


#Rename logging files and assign newly renamed files to variables for emailing
Rename-Item ".\ErrorLog.txt" -NewName ("ErrorLog" + $(get-date -Format yyyy-MM-dd@HH-mm-ss) + ".txt")
$errorLog = Get-ChildItem . -Filter ErrorLog*.txt | select -Last 1 -ExpandProperty Name

Rename-Item ".\ADModifyTranscript.txt" -NewName ("ADModifyTranscript" + $(get-date -Format yyyy-MM-dd@HH-mm-ss) + ".txt")
$transcript = Get-ChildItem . -Filter ADModifyTranscript*.txt | select -Last 1 -ExpandProperty Name


#If the errorLog is populated with data (if any errors happened) email the log and move it to a archive folder since a new file is not created everytime, if the file is not moved then it will send the last errorLog
If ($errorLog) {

                Send-MailMessage -SmtpServer distmail02.int.uhs.com -To mdmayer@uhs.com -From mdmayer@uhs.com -Subject "AD Update Script Error Log" -Body "ErrorLog file from updateADUserFromWorkday" -attachments $errorLog

                    If (Test-Path .\ErrorLogBackup) {
 
                                                    Move-Item $errorLog .\ErrorLogBackup\$errorLog -ErrorAction SilentlyContinue
                                                    
                                                    } 
                                                    
                                                      Else {

                                                            New-Item ErrorLogBackup -ItemType directory
                                                            Move-Item $errorLog .\ErrorLogBackup\$errorLog
                                                            
                                                            }
                                                            
               }


#Email the transaction log, no need to move the file since a new one is created everytime
Send-MailMessage -SmtpServer distmail02.int.uhs.com -To mdmayer@uhs.com -From mdmayer@uhs.com -Subject "AD Update Script Transcript" -Body "Transaction log file from updateADUserFromWorkday" -attachments $transcript