$creds = Get-Credential
Connect-VBRServer -Credential $creds -Server "Your VBR Server Name"
$csvDirectoryPath = "C:\temp\VMHistoryReport\"
$oneMonthAgo = (Get-Date).AddMonths(-1)
Get-VBRComputerBackupJobSession
# Get all relevant backup sessions and all their task sessions
$allSessions = Get-VBRComputerBackupJobSession | Where-Object { $_.EndTime -ge $oneMonthAgo }
$allTaskSessions = $allSessions | Get-VBRTaskSession

# Process all task sessions
$allSessionData = $allTaskSessions | ForEach-Object {
    $session = $_
    $jobname = $session.JobName
    $vmname = $session.Name
    $duration = $session.Progress.Duration
    $starttime = $session.Progress.StartTimeLocal
    $endtime = $session.Progress.StopTimeLocal
    $transferedBytes = $session.Progress.TransferedSize
    $transferredFormatted = "{0:N2} GB" -f ($transferedBytes / 1GB)
    $type = if ($session.IsFullMode) { "Full" } else { "Incremental" }
    if ($session.JobSess.Name -like "*Synthetic*") { $type = "Synthetic Full" }
    $result = $session.Status
    

    [PSCustomObject]@{
        "Job Name"          = $jobname
        "VM Name"           = $vmname
        "Backup Type"       = $type
        "Start Time"        = $starttime -replace ' ', '-'    
        "End Time"          = $endtime -replace ' ', '-' 
        "Duration"          = $duration
        "Transferred Data"  = $transferredFormatted
        "Result"            = $result
    }
}

# Export to CSV
$csvFilePath = Join-Path -Path $csvDirectoryPath -ChildPath "VMHistoryReport_AllAgents.csv"
$allSessionData | Export-Csv -Path $csvFilePath -NoTypeInformation -Force -Delimiter ';'
Write-Host "Combined backup session details for all VMs have been saved to $csvFilePath"

Read-Host -Prompt "Press Enter to exit"

