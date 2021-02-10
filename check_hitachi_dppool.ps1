################################################################
##                                                            ##
##   Purpose: This is script was designed to monitor          ##
##            the DP Pool size from the Hitachi Storages      ##
##            and display that info on Nagios Monitoring.     ##
##                                                            ##
##     Created by: Mark "The Automator" Borst                 ##
##     Version: 1.0                                           ##           
##     Last update date : 16/06/2020                          ##
##                                                            ##
##                                                            ##
##     Attention: This was created for Schneider Electric     ##
##                 Internal usage only                        ##
##                                                            ##
##     Changelog:                                             ##
################################################################



# You need to add the argument(Storage name) to run
# You need to add the argument(DP Pool number) to run
Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $storage,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $dpNumber
    )


# Create Variables
$return = 0
$temporary = "C:\Program Files (x86)\Storage Navigator Modular 2 CLI\Storage\$storage-temp-dppool$dpNumber.txt"
$temp = "C:\Program Files (x86)\Storage Navigator Modular 2 CLI\Storage\$storage-dppool$dpNumber-temp.csv"

# Login on the CLI Storage


$env:STONAVM_HOME="C:\Program Files (x86)\Storage Navigator Modular 2 CLI"
$env:STONAVM_ACT="on"
$env:STONAVM_RSP_PASS="on"
$env:LANG="en"


cd "C:\Program Files (x86)\Storage Navigator Modular 2 CLI" 

# audptrend that sends the output to a file
./audptrend -unit $storage -refer -dppoollist | Out-File -FilePath $temporary 

# Run audptrend command
$audptrend = ./audptrend -unit $storage -refer -dppoollist

# Separate the file in lines and delete the first 2 lines
$data = Get-Content -Path $temporary | select -Skip 2

# Separate the data(txt file) with tab spaces 
$objects = ForEach($record in $data) {
    $split = $record -split "\s{2,}|\t+"
    If($split.Length -gt $maxLength){
        $maxLength = $split.Length
    }
    $props = @{}
    For($i=0; $i -lt $split.Length; $i++) {
        $props.Add([String]($i+1),$split[$i])
    }
    New-Object -TypeName PSObject -Property $props
}


# Creates a header for the table
$headers = [String[]](1..$maxLength)

# Export the table created as a CSV file
$objects | 
Select-Object $headers | 
Export-Csv -NoTypeInformation -Path $temp

# Import a new CSV file (Couldn't figure out how to manipulate in a single file)
$data2= Import-Csv -Path $temp

# Check every line, searches for the DP Pool and changes the Terabyte to Gigabyte
Foreach($line in $data2){
    If($line.2 -match $dpNumber){
       $raidLevel = $line.3
	If($line.4 -like "*TB"){
	$totalCapacity = $line.4 -replace "\D", "$1"
	[int32]$totalCapacity = $totalCapacity
	$totalCapacity = $totalCapacity * 100
	}
	If($line.4 -like "*GB"){
	$totalCapacity = $line.4 -replace "\D", "$1"
	[int32]$totalCapacity = $totalCapacity
	$totalCapacity = $totalCapacity / 10
	}
	If($line.5 -like "*GB"){
	$usedCapacity = $line.5 -replace "\D", "$1"
	[int32]$usedCapacity = $usedCapacity
	$usedCapacity = $usedCapacity / 10
	}
	If($line.5 -like "*TB"){
	$usedCapacity = $line.5 -replace "\D", "$1"
	[int32]$usedCapacity = $usedCapacity
	$usedCapacity = $usedCapacity * 100
	}
}
}

# Find the percent
$percentage = $usedCapacity / $totalCapacity

# Show as a rounded number
$percent = [math]::Round($percentage * 100)

# Check if the percent is ok 
if ($percentage -gt 0.90)
    {
        $return = 2
    }   ElseIf ($percentage -gt 0.75) {
        $return = 1
}

# Delete $temporary and $temp after used
Remove-Item $temporary
Remove-Item $temp

#If the DP Pool is almost full, exits with CRITICAL status '2'
if ($return -eq 2)
{
Write-Host "CRITICAL: DP Pool size near full!!Total($totalCapacity GB), using ($usedCapacity GB/$percent%). Raid Level:$raidLevel." 
exit $return
}

#If the size is between 25% to 10%, exits with WARNING status '1'
if ($return -eq 1)
{
Write-Host "WARNING: DP Pool size is Total($totalCapacity GB), using ($usedCapacity GB/$percent%). Raid Level:$raidLevel."
exit $return
}

#If everything is ok, exits with OK status '0'
write-host "OK: DP Pool size is good. Total($totalCapacity GB), using ($usedCapacity GB/$percent%). Raid Level:$raidLevel."
exit $return