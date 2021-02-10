################################################################
##                                                            ##
##   Purpose: This is script was designed to monitor          ##
##            the drives from the Hitachi Storages            ##
##            and display that info on Nagios Monitoring.     ##
##                                                            ##
##     Created by: Mark "The Automator" Borst                 ##
##     Version: 1.0                                           ##           
##     Last update date : 06/05/2020                          ##
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
$log = "C:\Program Files (x86)\Storage Navigator Modular 2 CLI\Storage\$storage-drives.txt"
$status = ""
$newline = "`n"
$sparecount = 0 

# Login on the CLI Storage


$env:STONAVM_HOME="C:\Program Files (x86)\Storage Navigator Modular 2 CLI"
$env:STONAVM_ACT="on"
$env:STONAVM_RSP_PASS="on"
$env:LANG="en"


cd "C:\Program Files (x86)\Storage Navigator Modular 2 CLI" 

# audrive that sends the output to a file
./audrive -unit $storage -status | Out-File -FilePath $log

# Run auparts command
$audrive = ./audrive -unit $storage -status

# Check we don't have any spare drive left

ForEach ($line in $audrive) 
{
    if ($line -like "*Standby*")
	{
            $sparecount = $sparecount + 1
            $status = $status + $line + $newline
	}
    
}

# Change return value if spare count is less than 2
if ($sparecount -lt 2)
        {
            $return = 1 
        }

# Check if any line has the failed status
ForEach ($line in $audrive) 
{
    if (($line -like "*Aborted*") -or ($line -like "*Detach*"))
	{
	    $return = 2
	    $status = $status + $line + $newline
	}
}

#If anything failed, exits with CRITICAL status '2'
if ($return -eq 2)
{
Write-Host "CRITICAL - Something Failed! Click to see output " $newline "Unit  HDU Type        Status" $newline $status 
exit $return
}

#If we don't have a spare disk, exits with WARNING status '1'
if ($return -eq 1)
{
Write-Host "WARNING - Something Failed! Click to see output " $newline "Unit  HDU Type        Status" $newline $status 
exit $return
}

#If everything is ok, exits with OK status '0'
write-host "OK - All drives are good"
exit $return