################################################################
##                                                            ##
##   Purpose: This is script was designed to monitor          ##
##            the peripherals from the Hitachi Storages       ##
##            and display that info on Nagios Monitoring.     ##
##                                                            ##
##     Created by: Mark "The Automator" Borst                 ##
##     Version: 1.0                                           ##           
##     Last update date : 05/05/2020                          ##
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
$log = "C:\Program Files (x86)\Storage Navigator Modular 2 CLI\Storage\$storage-parts.txt"
$status = ""
$newline = "`n" 

# Login on the CLI Storage


$env:STONAVM_HOME="C:\Program Files (x86)\Storage Navigator Modular 2 CLI"
$env:STONAVM_ACT="on"
$env:STONAVM_RSP_PASS="on"
$env:LANG="en"


cd "C:\Program Files (x86)\Storage Navigator Modular 2 CLI" 

# Old auparts that sends the output to a file
./auparts -unit $storage | Out-File -FilePath $log

# Run auparts command
$auparts = ./auparts -unit $storage

# Check if any line has the failed status
ForEach ($line in $auparts) 
{
    if (($line -like "*Failed*") -or ($line -like "*Detach*"))
	{
	    $return = 2
	    $status = foreach($reportline in [System.IO.File]::ReadLines($log))
                {
                    $reportline + $newline
                }
	}
}

#If anything failed, exit with CRITICAL status '2'
if ($return -eq 2)
{
Write-Host "CRITICAL - Something Failed! Click to see output " $newline $status
exit $return
}

#If everything is ok, enter this loop and exit with OK status '1'
write-host "OK - All peripherals are good"
exit $return