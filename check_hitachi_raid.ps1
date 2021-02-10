################################################################
##                                                            ##
##   Purpose: This is script was designed to monitor          ##
##            the raid size from the Hitachi Storages         ##
##            and display that info on Nagios Monitoring.     ##
##                                                            ##
##     Created by: Mark "The Automator" Borst                 ##
##     Version: 1.0                                           ##           
##     Last update date : 07/05/2020                          ##
##                                                            ##
##                                                            ##
##     Attention: This was created for Schneider Electric     ##
##                 Internal usage only                        ##
##                                                            ##
##     Changelog:                                             ##
################################################################



param([string]$storage) # You need to add the argument(Storage name) to run



# Create Variables
$return = 0
$temporary = "C:\Program Files (x86)\Storage Navigator Modular 2 CLI\Storage\$storage-temp-raid.txt"
$log = "C:\Program Files (x86)\Storage Navigator Modular 2 CLI\Storage\$storage-raid.txt"

# Login on the CLI Storage


$env:STONAVM_HOME="C:\Program Files (x86)\Storage Navigator Modular 2 CLI"
$env:STONAVM_ACT="on"
$env:STONAVM_RSP_PASS="on"
$env:LANG="en"


cd "C:\Program Files (x86)\Storage Navigator Modular 2 CLI" 

# aurgref that sends the output to a file
./aurgref -unit $storage -g | Out-File -FilePath $temporary 

# Run aurgref command
$aurgref = ./aurgref -unit $storage -g

# Separate the file in lines
$data = Get-Content -Path $temporary

# This is a "gambiarra" or a trick to remove a line from the text file
$data = $data -replace "\dD\+1P\)",""

# Splits the file in new lines and save it as a log
$split = $data -split "\s+" | Out-File -FilePath $log

# Picks only the numbers from the line (The index is the line number)
[int32]$total = Get-Content $log | Select -Index 25
[int32]$free = Get-Content $log | Select -Index 27

# Add the values to give the Total
$used = $total - $free

# Find the percent
$percentage = $used / $total

# Show as a rounded number
$percent = [math]::Round($percentage * 100)

# Check if the percent is ok 
if ($percentage -gt 0.90)
    {
        $return = 2
    }   ElseIf ($percentage -gt 0.75) {
        $return = 1
}

# Delete $temporary after used
Remove-Item $temporary

#If the size is almost full, exits with CRITICAL status '2'
if ($return -eq 2)
{
Write-Host "CRITICAL - Storage size near full!!Total($total GB), using ($used GB/$percent%)." 
exit $return
}

#If the size is between 25% to 10%, exits with WARNING status '1'
if ($return -eq 3)
{
Write-Host "WARNING - Storage size is Total($total GB), using ($used GB/$percent%)."
exit $return
}

#If everything is ok, exits with OK status '0'
write-host "OK - Storage size is good. Total($total GB), using ($used GB/$percent%)."
exit $return