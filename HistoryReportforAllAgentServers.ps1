$logFile = "C:\temp\VMHistoryReport\VMHistoryReport.log"
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp [$Level] $Message"
}

Write-Log "Script started."
$creds = Get-Credential
Write-Log "Credentials obtained."
Connect-VBRServer -Credential $creds -Server "Your VBR Server Name"
Write-Log "Connected to VBR server."

$csvDirectoryPath = "C:\temp\VMHistoryReport\"
$oneMonthAgo = (Get-Date).AddMonths(-1)

Write-Log "Getting all relevant backup sessions."
$allSessions = Get-VBRComputerBackupJobSession | Where-Object { $_.EndTime -ge $oneMonthAgo }
Write-Log "$($allSessions.Count) sessions found."

Write-Log "Getting all task sessions."
$allTaskSessions = $allSessions | Get-VBRTaskSession
Write-Log "$($allTaskSessions.Count) task sessions found."

Write-Log "Identifying special job names."
$specialJobNames = $allTaskSessions | Where-Object { $_.JobName -like '*SOLARIS*' -or $_.JobName -like '*AIX*' } | Select-Object -ExpandProperty JobName -Unique
Write-Log "$($specialJobNames.Count) special jobs found: $($specialJobNames -join ', ')"

$backups = @{}
foreach ($job in $specialJobNames) {
    Write-Log "Getting backup object for job: $job"
    $backup = Get-VBRBackup -Name $job -ErrorAction SilentlyContinue
    if ($backup) {
        $backups[$job] = $backup
        Write-Log "Backup object found for job: $job"
    } else {
        Write-Log "No backup found for job: $job" "WARNING"
    }
}

$restorePointsByJobAndVM = @{}
foreach ($job in $specialJobNames) {
    if ($backups.ContainsKey($job)) {
        Write-Log "Fetching restore points for job: $job"
        $allRPs = Get-VBRRestorePoint -Backup $backups[$job]
        $restorePointsByJobAndVM[$job] = $allRPs | Group-Object -Property Name
        Write-Log "$($allRPs.Count) restore points grouped for job: $job"
    }
}

Write-Log "Processing session data."
$allSessionData = foreach ($session in $allTaskSessions) {
    $jobname = $session.JobName 
    $vmname = $session.Name
    Write-Log "Processing session for job: $jobname, VM: $vmname"
    $duration = $session.Progress.Duration
    $starttime = $session.Progress.StartTimeLocal
    $endtime = $session.Progress.StopTimeLocal
    $transferedBytes = $session.Progress.TransferedSize
    $transferredFormatted = "{0:N2} GB" -f ($transferedBytes / 1GB)
    $type = if ($session.IsFullMode) { "Full" } else { "Incremental" }
    if ($session.JobSess.Name -like "*Synthetic*") { $type = "Synthetic Full" }
    $result = $session.Status

    if ($jobname -like '*SOLARIS*' -or $jobname -like '*AIX*') {
        if ($restorePointsByJobAndVM.ContainsKey($jobname)) {
            $vmGroup = $restorePointsByJobAndVM[$jobname] | Where-Object { $_.Name -eq $vmname }
            if ($vmGroup) {
                $RPs = $vmGroup.Group | Where-Object { $_.CreationTime.Date -eq $starttime.Date }
                $latestFullRP = $RPs | Where-Object { $_.Type -ilike '*Full*' -or $_.Algorithm -ilike "*Full*" } | Sort-Object CreationTime -Descending | Select-Object -First 1

                if ($latestFullRP -and $starttime.Date -eq $latestFullRP.CreationTime.Date) {
                    $type = "Full"
                }
                Write-Log "Restore point determined for VM: $vmname, Type: $type"
            } else {
                Write-Log "No restore points found for VM: $vmname in job: $jobname" "WARNING"
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

Write-Log "Exporting session data to CSV."
$csvFilePath = Join-Path -Path $csvDirectoryPath -ChildPath "VMHistoryReport_AllAgents.csv"
$allSessionData | Export-Csv -Path $csvFilePath -NoTypeInformation -Force -Delimiter ';'
Write-Log "Combined backup session details exported to $csvFilePath"

Write-Host "Combined backup session details for all VMs have been saved to $csvFilePath"
Write-Log "Script completed successfully." "SUCCESS"

Read-Host -Prompt "Press Enter to exit" 

