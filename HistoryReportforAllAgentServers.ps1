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

$restorePointsByJobAndVM = @{}
foreach ($job in $specialJobNames) {
    if ($backups.ContainsKey($job)) {
        $allRPs = Get-VBRRestorePoint -Backup $backups[$job]
        # Organize restore points by VM name for quick lookup
        $restorePointsByJobAndVM[$job] = $allRPs | Group-Object -Property Name
    }
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
        if ($restorePointsByJobAndVM.ContainsKey($jobname)) {
            # Find the correct group for this VM
            $vmGroup = $restorePointsByJobAndVM[$jobname] | Where-Object { $_.Name -eq $vmname }
            if ($vmGroup) {
                $RPs = $vmGroup.Group | Where-Object { $_.CreationTime.Date -eq $starttime.Date }
                $latestFullRP = $RPs | Where-Object { $_.Type -ilike '*Full*' -or $_.Algorithm -ilike "*Full*" } | Sort-Object CreationTime -Descending | Select-Object -First 1

            if ($latestFullRP -and $starttime.Date -eq $latestFullRP.CreationTime.Date) {
                $type = "Full"
                }
            }
        }
    }

    [PSCustomObject]@{
        "Job Name"          = $jobname
        "Server Name"       = $vmname
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

 



