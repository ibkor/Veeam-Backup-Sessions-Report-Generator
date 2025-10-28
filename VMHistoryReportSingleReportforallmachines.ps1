#$creds = Get-Credential
#Connect-VBRServer -Credential $creds -Server "Your VBR Server Name"

$csvDirectoryPath = "C:\temp\VMHistoryReport\" # Output folder

$oneMonthAgo = (Get-Date).AddMonths(-1)

# Get all backup sessions from the last month
$allSessions = Get-VBRBackupSession | Where-Object { $_.EndTimeUTC -ge $oneMonthAgo } | Sort-Object EndTimeUTC -Descending

# Get all unique VM names from those sessions
$allVMNames = $allSessions | Get-VBRTaskSession | Select-Object -ExpandProperty Name | Sort-Object -Unique

# Prepare an array to hold all session details
$allSessionData = @()

foreach ($vmNameInput in $allVMNames) {
    # All backup task sessions for this specific VM from the last month
    $sessions = $allSessions | Get-VBRTaskSession -Name $vmNameInput

    foreach ($session in $sessions) {
        $jobname = $session.JobName
        $vmname = $session.Name 
        $duration = $session.Progress.Duration
        $starttime = $session.Progress.StartTimeLocal    
        $processeddata = "{0:N2} GB" -f ($session.Progress.ProcessedSize / 1GB)
        $transferreddata = "{0:N2} GB" -f ($session.Progress.TransferedSize / 1GB)
        $avgSpeed = "{0:N1} MB/s" -f ($session.Progress.AvgSpeed / 1MB)
        $type = if ($session.IsFullMode) { "Full" } else { "Incremental" }
        if ($session.JobSess.Name -like "*Synthetic*") { $type = "Synthetic Full" }
        $result = $session.Status

        $sessionDetails = [PSCustomObject]@{
            "Job Name"          = $jobname
            "VM Name"           = $vmname
            "Job Type"          = $type
            "Start Time"        = $starttime        
            "Duration"          = $duration
            "Average Speed"     = $avgSpeed
            "Processed Data"    = $processeddata
            "Transferred Data"  = $transferreddata
            "Result"            = $result
        }

        $allSessionData += $sessionDetails
    }
}

# Define the CSV file path for the combined report
$csvFilePath = Join-Path -Path $csvDirectoryPath -ChildPath "VMHistoryReport_AllVMs.csv"

# Export the combined session data to a single CSV file
$allSessionData | Export-Csv -Path $csvFilePath -NoTypeInformation -Force -Delimiter ';'

Write-Host "Combined backup session details for all VMs have been saved to $csvFilePath"
Read-Host -Prompt "Press Enter to exit"