$creds = Get-Credential
Connect-VBRServer -Credential $creds -Server "Your VBR Server Name"
$csvDirectoryPath = "C:\temp\VMHistoryReport\"
$oneMonthAgo = (Get-Date).AddMonths(-1)

# Get all relevant backup sessions and their task sessions up front
$allSessions = Get-VBRComputerBackupJobSession | Where-Object { $_.EndTime -ge $oneMonthAgo }
$allTaskSessions = $allSessions | Get-VBRTaskSession

# Pre-fetch all backups and restore points for special job types
$specialJobNames = $allTaskSessions | Where-Object { $_.JobName -like '*SOLARIS*' -or $_.JobName -like '*AIX*' } | Select-Object -ExpandProperty JobName -Unique
$backups = @{}
foreach ($job in $specialJobNames) {
    $backup = Get-VBRBackup -Name $job -ErrorAction SilentlyContinue
    if ($backup) { $backups[$job] = $backup }
}

$allSessionData = foreach ($session in $allTaskSessions) {
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

    # Only fetch restore points if necessary
    if ($jobname -like '*SOLARIS*' -or $jobname -like '*AIX*') {
        if ($backups.ContainsKey($jobname)) {
            $RPs = Get-VBRRestorePoint -Backup $backups[$jobname] -Name $vmname | Where-Object {
                $_.CreationTime.Date -eq $starttime.Date
            }
            if ($RPs.Type -ilike '*Full*' -or $RPs.Algorithm -ilike "*Full*") {
                $type = "Full"
            }
        }
    }

    [PSCustomObject]@{
        "Job Name"          = $jobname
        "VM Name"           = $vmname
        "Backup Type"       = $type
        "Start Time"        = $starttime   
        "End Time"          = $endtime 
        "Duration"          = $duration
        "Transferred Data GB"  = $transferredFormatted
        "Result"            = $result
    }
}

# Export to CSV
$csvFilePath = Join-Path -Path $csvDirectoryPath -ChildPath "VMHistoryReport_AllAgents.csv"
$allSessionData | Export-Csv -Path $csvFilePath -NoTypeInformation -Force -Delimiter ';'
Write-Host "Combined backup session details for all VMs have been saved to $csvFilePath"
Read-Host -Prompt "Press Enter to exit"


