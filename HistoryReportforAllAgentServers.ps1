 $creds = Get-Credential
Connect-VBRServer -Credential $creds -Server "Your VBR Server Name"

$csvDirectoryPath = "C:\temp\VMHistoryReport\"
$oneMonthAgo = (Get-Date).AddMonths(-1)

$allSessions = Get-VBRComputerBackupJobSession | Where-Object { $_.EndTime -ge $oneMonthAgo }
$allTaskSessions = $allSessions | Get-VBRTaskSession

$needsRpCheck = $allTaskSessions.Where({ $_.JobName -match 'SOLARIS|AIX' }, 'Default')
$backupsByName = Get-VBRBackup | Group-Object -Property Name -AsHashTable -AsString

$rpIndex = @{}
foreach ($jobName in ($needsRpCheck.JobName | Select-Object -Unique)) {
    $backup = $backupsByName[$jobName]
    if (-not $backup) { continue }

    # Get all RPs for this backup once, last month window to reduce volume
    $rps = Get-VBRRestorePoint -Backup $backup | Where-Object { $_.CreationTime -ge $oneMonthAgo }
    foreach ($rp in $rps) {
        $key = ('{0}|{1}' -f $rp.Name.ToLowerInvariant(), $rp.CreationTime.Date.ToString('yyyy-MM-dd'))
        # Store the "best" type seen for the key (Full outranks Incremental)
        if (-not $rpIndex.ContainsKey($key) -or $rp.Type -like '*Full*') {
            $rpIndex[$key] = $rp.Type
        }
    }
}

# Build rows
$allSessionData = foreach ($session in $allTaskSessions) {
    $jobname = $session.JobName
    $vmname = $session.Name
    $duration = $session.Progress.Duration
    $starttime = $session.Progress.StartTimeLocal
    $endtime = $session.Progress.StopTimeLocal
    $transferedBytes = $session.Progress.TransferedSize
    $transferredFormatted = '{0:N2} GB' -f ($transferedBytes / 1GB)

    $type = if ($session.IsFullMode) { 'Full' } else { 'Incremental' }
    if ($session.JobSess.Name -like '*Synthetic*') { $type = 'Synthetic Full' }

    # Only adjust type for SOLARIS/AIX by using the cached RP index
    if ($jobname -match 'SOLARIS|AIX') {
        $key = ('{0}|{1}' -f $vmname.ToLowerInvariant(), $starttime.Date.ToString('yyyy-MM-dd'))
        if ($rpIndex.TryGetValue($key, [ref]$null)) {
            if ($rpIndex[$key] -ilike '*Full*') { $type = 'Full' }
        }
    }

    [PSCustomObject]@{
        'Job Name'         = $jobname
        'VM Name'          = $vmname
        'Backup Type'      = $type
        'Start Time'       = $starttime
        'End Time'         = $endtime
        'Duration'         = $duration
        'Transferred Data' = $transferredFormatted
        'Result'           = $session.Status
    }
}

# Export to CSV
$csvFilePath = Join-Path -Path $csvDirectoryPath -ChildPath 'VMHistoryReport_AllAgents.csv'
$allSessionData | Export-Csv -Path $csvFilePath -NoTypeInformation -Force -Delimiter ';'
Write-Host "Combined backup session details for all VMs have been saved to $csvFilePath"

Read-Host -Prompt 'Press Enter to exit' 
