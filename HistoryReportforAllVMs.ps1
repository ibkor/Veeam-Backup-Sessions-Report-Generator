$creds = Get-Credential
Connect-VBRServer -Credential $creds -Server "Your VBR Server Name"
$csvDirectoryPath = "C:\temp\VMHistoryReport\"
$oneMonthAgo = (Get-Date).AddMonths(-1)

# Get all relevant backup sessions and all their task sessions
$allSessions = Get-VBRBackupSession | Where-Object { $_.EndTimeUTC -ge $oneMonthAgo }
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
    if (-not $transferedBytes) { $transferedBytes = 0 }
    $transferredFormatted = "{0:N2} GB" -f ($transferedBytes / 1GB)
    $avgSpeed = "{0:N1} MB/s" -f ($session.Progress.AvgSpeed / 1MB)
    $type = if ($session.IsFullMode) { "Full" } else { "Incremental" }
    if ($session.JobSess.Name -like "*Synthetic*") { $type = "Synthetic Full" }
    $result = $session.Status
    

    [PSCustomObject]@{
        "Job Name"          = $jobname
        "VM Name"           = $vmname
        "Backup Type"       = $type
        "Start Time"        = $starttime
        "End Time"          = $endtime        
        "Duration"          = $duration
        "Transferred Data"  = $transferredFormatted
        "Result"            = $result
    }
}

# Export to CSV
$csvFilePath = Join-Path -Path $csvDirectoryPath -ChildPath "VMHistoryReport_AllVMs.csv"
$allSessionData | Export-Csv -Path $csvFilePath -NoTypeInformation -Force -Delimiter ';'
Write-Host "Combined backup session details for all VMs have been saved to $csvFilePath"

Read-Host -Prompt "Press Enter to exit"
