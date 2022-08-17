<#
.SYNOPSIS
  Name: Monitor-NetworkLatency.ps1
  The purpose of this script is to monitor the latency of the internal network
  
.DESCRIPTION
  This script will ping key firewalls/servers and report on their latency

.NOTES
    Release Date: 2019-12-16T10:01
    Last Updated: 2019-12-19T10:10
   
    Author: Luke Nichols

    This script is meant to be run as a scheduled task.
#>

#In order to make debugging in PowerShell ISE easier, clear the screen at the start of the script
Clear-Host

### Dot-source functions from C:\Scripts\includes\ ###
. "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\includes\Write-Log.ps1"
. "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\includes\Delete-OldFiles.ps1"

### Define variables ###

#Get the current date
[DateTime]$currentDate=Get-Date

#Grab the individual portions of the date and put them in vars
$currentYear = $($currentDate.Year)
$currentMonth = $($currentDate.Month).ToString("00")
$currentDay = $($currentDate.Day).ToString("00")

$currentHour = $($currentDate.Hour).ToString("00")
$currentMinute = $($currentDate.Minute).ToString("00")
$currentSecond = $($currentDate.Second).ToString("00")

#$Target = "google.com" #Uncomment for testing, average response time is ~9 ms
#$Target = "buzzoff.kettering.edu"
#$Target = "chief.kettering.edu"
#$Target = "hades1.kettering.edu"
#$Target = "ikol.kettering.edu"
#$Target = "scout.kettering.edu"
$Target = "styx1.kettering.edu"

$LogFilePath = "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\logs\$($Target)_$($currentYear)-$($currentMonth)-$($currentDay)T$($currentHour)$($currentMinute)$($currentSecond).txt"
Write-Host "`$LogFilePath: $LogFilePath"

$MaximumAcceptableResponseTime = 5

### Open log file ###
Write-Log -LogString "Opening log file" -LogFilePath $LogFilePath -LogRotateDays 30

### Script main body ###

$PingResult = Test-Connection -Count 20 -computername $Target

[int32]$TotalResponseTime = 0

Write-Host "ResponseTime for $($Target): "

#Average the ResponseTime values of each ping
foreach ($ResponseTime in $PingResult.ResponseTime) {
    $TotalResponseTime += $ResponseTime
    Write-Host "$ResponseTime ms"
}
$ResponseTimeAvg = [math]::Round(($TotalResponseTime / $PingResult.Count), 2)

#Test to see if the average ping is acceptable or not and report the results
if ($ResponseTimeAvg -le $MaximumAcceptableResponseTime) {
    $LogString = "Average response time to $Target ($ResponseTimeAvg ms) is within acceptable limit ($MaximumAcceptableResponseTime ms)"
    Write-Log -LogString $LogString -LogFilePath $LogFilePath
    Write-Host $LogString
    $LogString = ""
} elseif ($ResponseTimeAvg -gt $MaximumAcceptableResponseTime) {
    $LogString = "Average response time to $Target ($ResponseTimeAvg ms) is beyond acceptable limit ($MaximumAcceptableResponseTime ms)"
    Write-Log -LogString "$LogString" -LogFilePath $LogFilePath
    Write-Host $LogString -ForegroundColor Red

    #Send alert email
    $emailParams = @{'Body'=$LogString;
                'From'="$env:computername@ku.kettering.edu";
                'SmtpServer'="mailhost.kettering.edu";
                'Subject'="$($Target) Network Response Time Report $($currentYear)-$($currentMonth)-$($currentDay)T$($currentHour)$($currentMinute)";
                'To'="security@kettering.edu","8104233577@messaging.sprintpcs.com","8103482859@vtext.com","8106143509@messaging.sprintpcs.com"
                }
    Send-MailMessage @emailParams
    $LogString = ""
}


## Close log file ##
Write-Log -LogString "Close log file." -LogFilePath $LogFilePath -LogRotateDays 30

### End of script main body ###
break
exit