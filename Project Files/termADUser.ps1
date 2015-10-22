<#
Program:      termADUser.ps1
Author:       Mark Mayer 05929
Date:         July 31st 2015
Description:  Determines if a user is employed here and if not, it terminates their AD account automatically if they are no longer employed here
Prerequisite: Powershell v3.0 
#>

#Sets up transactional logging
Remove-Item ".\termADUserTranscript.txt"
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path ".\termADUserTranscript.txt" -append



Import-Module ActiveDirectory


#Pulls UHSEMPS.cvs from the IFS of the iSeries
#$workday = Import-CSV -Path \\Natasha\root\home\MDMAYER01\UHSEMPS.csv
$workday = Import-CSV -Path \\iUHSPRD1\root\vendors\workday\UHSEMPS.csv


#Deletes the temporary tables from the last run of the script
Remove-Item .\result.csv
Remove-Item .\workdayUsersActive.csv
Remove-Item .\workdayUsersActiveNoFindInAD.csv
Remove-Item .\workdayUsersCompare.csv
Remove-Item .\workdayUsersTerminated.csv
Remove-Item .\workdayUsersTerminatedNoFindInAD.csv


#Parses each line of UHSEMPS.csv
foreach ($line in $workday) {

#Log files for employees not found
$logfileA = ".\workdayUsersActiveNoFindInAD.csv"
$logfileT = ".\workdayUsersTerminatedNoFindInAD.csv"
    
    #Output for users not found in AD, this is because there is missing metadata in the AD schema or the field in Workday is blank
    $output = "User: " + $line.Full_Name + " " + $line.Employee_ID
    
    
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
    $job_Family      = $line.Job_Family
    $job_Title       = $line.Job_Title
    $last_Name       = $line.Last_Name
    $manager_ID      = $line.Manager_ID
    $middle_Name     = $line.Middle_Name
    $work_Phone      = $line.Work_Phone

   

#Finds user with status of "Active" or "Leave" (leave means that the user is still active so we'll treat it the same)	
If ($employee_Status -eq 'A' -or $employee_Status -eq 'L') {

    Try {
        
        #Find active Workday employees in AD
        Get-ADUser -Filter {emailaddress -eq $email} | Select sAMAccountName | Export-CSV -Append .\workdayUsersActive.csv
        #Get-ADUser -LDAPFilter "(employeeID=$employee_ID)" -Properties employeeID, sAMAccountName | Select sAMAccountName | Export-CSV -Append .\workdayUsersActive.csv
        
        }
        
        Catch {
              
              $output + " attribute is missing in AD or Workday attribute is blank" | Out-File $logfileA -Append
              
              }

     } 
          
     
     else {

          Try {
          
              #Find terminated Workday employees in AD (terminated can mean they changed rolls in the company)
              Get-ADUser -Filter {emailaddress -eq $email} | Select sAMAccountName | Export-CSV -Append .\workdayUsersTerminated.csv
              #Get-ADUser -LDAPFilter "(employeeID=$employee_ID)" -Properties employeeID, sAMAccountName | Select sAMAccountName | Export-CSV -Append .\workdayUsersTerminated.csv

              }

              Catch {

                    $output + " attribute is missing in AD or Workday attribute is blank" | Out-File $logfileT -Append
                    
                    }

         }
}

#Scrub tables so only unique values remain
$term = Import-Csv .\workdayUsersTerminated.csv | Sort sAMAccountName -Unique
$active = Import-CSV .\workdayUsersActive.csv | Sort sAMAccountName -Unique  

#Compare scrubbed results and keep sAMAccountNames that are only present in the terminated table, if they are in both in indicates that the employee has changed roles and is still employed here
Compare-Object $term $active -property sAMAccountName -IncludeEqual | Where-Object {$_.SideIndicator -eq '<='} | Select sAMAccountName | Export-Csv .\workdayUsersCompare.csv

$compare = Import-Csv .\workdayUsersCompare.csv

foreach ($line in $compare) {

$sam = $line.sAMAccountName

#Uncomment line to get a report
#Get-ADUser $sam | Export-Csv -Append .\result.csv

#This line automatically feeds those results to the Disable-ADAccount cmdlet
Disable-ADAccount -Identity $sam
echo $sam

}

Stop-Transcript

#Rename transactional logging file and keep for records
Rename-Item -Path ".\termADUserTranscript.txt" -NewName (".\termADUserTranscript" + $(get-date -Format yyyy-MM-dd) + ".txt")