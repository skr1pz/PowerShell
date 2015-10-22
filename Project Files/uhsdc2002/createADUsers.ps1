<#
Program:      createADUsers.ps1
Author:       Mark Mayer 05929
Date:         August 21th 2015
Description:  First SQL join your data from Workday and Lotus export file
Prerequisite: Powershell v3.0 
#>

#Checks to see if UAC has an Administrator token and grants one if needed
#if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

#Set-ExecutionPolicy Bypass

#Sets up transactional logging
Remove-Item ".\ADModifyTranscript.txt"
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path ".\ADModifyTranscript.txt" -Append



Import-Module ActiveDirectory


#Pulls the feeder file
$feed = Import-CSV -Path C:\Users\MDMAYER01\newUsers.csv




#Parses each line of UHSEMPS.csv
foreach ($line in $feed) {
pause
 
    
    #Parsed columns in UHSEMPS.csv 
    $Short   = $line.Short
    $Name    = $line.Name
    $Email   = $line.Email
  
    $initialpassword = "password"
  
    $setpass = ConvertTo-SecureString -AsPlainText $initialpassword -force
  
  
  Try {
  
  New-ADUser -SamAccountName $line.Short -Name $line.Short -DisplayName $line.Name -EmailAddress $line.Email -UserPrincipalName "$($line.Short)@int.uhs.com" -AccountPassword $setpass -Enabled:$true -ChangePasswordAtLogon:$true
       
	   } Catch {}
	   
	   
  
    
}

Stop-Transcript


