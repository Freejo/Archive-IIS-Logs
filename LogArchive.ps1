<#

LogArchive.ps1
Version 0.3

0.1 Initial script
0.2 added Try-Catch for extra logging on archive creation
0.3 added script output log parameter

Written by: Erwin van der Lit

Script to archive(zip) log files in a folder recursively and move files older than specified
to a subfolder (_Archive). Some basic check are included to not remove source log file when destination zip file is not created

.Parameter path
The folder to recursively look in

.Parameter mask
The File Extensions of files which should be archived
multiple extensions may be given in comma-separated format
example: logarchive.ps1 -Path e:\logfiles -mask *.log,*.txt -days 7

.Parameter days
amount of days older than which should be archived

.Parameter log
Specifies the location of the logfile of this script
Note: folder is not created by this script. make sure it exists-ExecutionPolicy Bypass C:\Users\ErwinvanderLit\Documents\LogArchive.ps1 -Path e:\logfiles\IIS -mask *.log -days 3 -log e:\logfiles\scripts

.Usage
logarchive.ps1 -Path e:\logfiles\IIS -mask *.log -days 7 -log e:\logfiles\scripts

.To Schedule
In Task scheduler, add action: Start a Program --> "powershell.exe"
Add Arguments --> "-ExecutionPolicy Bypass E:\Path\TO\LogArchive.ps1 -Path e:\logfiles\IIS -mask *.log -days 3 -log e:\logfiles\scripts"

#>

[CmdletBinding()]
param (
	[Parameter( Mandatory=$true)]
	[string]$path,

    [Parameter (Mandatory=$true)]
    [array]$mask,

    [Parameter( Mandatory=$true)]
	[string]$days,

    [Parameter( Mandatory=$true)]
	[string]$log

	)

#-------------------------------------------------
#  Variables
#-------------------------------------------------
$computername = $env:computername
$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$lfoutput = "$log\$(get-date -Format yyyyMMdd)-logsarchive.log"

$children = get-childitem -recurse -Path $Path -Include $mask |
  where-object {$_.LastWriteTime -lt (get-date).AddDays(-$days)}


#...................................
# Logfile Strings
#...................................

$logstring0 = "====================================="
$logstring1 = " Log File Cleanup Script"


#-------------------------------------------------
#  Functions
#-------------------------------------------------

#This function is used to write the log file for the script
Function Write-Logfile()
{
	param( $logentry )
	$timestamp = Get-Date -DisplayHint Time
	"$timestamp $logentry" | Out-File $lfoutput -Append
}




#-------------------------------------------------
#  Script
#-------------------------------------------------

$timestamp = Get-Date -DisplayHint Time
"$timestamp $logstring0" | Out-File $lfoutput -Append
Write-Logfile $logstring1
Write-Logfile "  $now"
Write-Logfile $logstring0

write-host $mydir


foreach($child in $children)
{
          
     $spath = $child.Directory
     $dpath = "$spath\_Archive"
     
     if(!(test-path $dpath))
        {
            New-Item -ItemType Directory -Force -Path $dpath
        }
    
    $ZipFileName = $child.Name+".zip"
    $ZipFullFileName = "$dpath\$ZipFileName"
    
    
    if(-not (test-path($ZipFullFileName)))
    {
        
        write-logfile "INFO: Creating archive $ZipFullFileName" 
        
        Try {
            Compress-Archive $child $ZipFullFileName -ErrorAction Stop
            }
        Catch{
            $errormessage = ($error[0]| out-string).Split([Environment]::NewLine) | Select -First 1
            write-logfile "ERROR: $errormessage"
            }       

        if (test-path $ZipFullFileName){
            Write-logfile "INFO: Removing $child"
            remove-item $child 
            }
        else {
            Write-logfile "ERROR: $ZipFullFileName Did not create, so I'm not deleting"
            }              
    }
        Else
    {
                    $tmpstring = "WARNING: Destination zip file " +$child + " already exists, skipping"
                    Write-logfile $tmpstring               
    }    
}

#Cleanup old script output logs greater than 30 days
get-childitem $lfoutput | Where LastWriteTime -LT (Get-Date).AddDays(-30)|Remove-item
