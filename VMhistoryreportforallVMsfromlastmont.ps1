$csvDirectoryPath = "C:\temp\VMHistoryReport\" # Output folder

# Get the date one month ago
$oneMonthAgo = (Get-Date).AddMonths(-1)

# Get all backup sessions from the last month
$allSessions = Get-VBRBackupSession | Where-Object { $_.EndTimeUTC -ge $oneMonthAgo } | Sort-Object EndTimeUTC -Descending

# Get all unique VM names from all backup sessions in the last month
$allVMNames = $allSessions | Get-VBRTaskSession | Select-Object -ExpandProperty Name | Sort-Object -Unique

foreach ($vmNameInput in $allVMNames) {
    # All backup task sessions for this specific VM from the last month
    $sessions = $allSessions | Get-VBRTaskSession -Name $vmNameInput

    $sessionData = @()
    $successCount = 0
    $warningCount = 0
    $failedCount = 0
    $totalCount = 0

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

        $totalCount++
        if ($result -eq "Success") {
            $successCount++
        }
        if ($result -eq "Warning") {
            $warningCount++
            $successCount++  
        }
        if ($result -eq "Failed") {
            $failedCount++
        }

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

        $sessionData += $sessionDetails
    }

    $successRate = if ($totalCount -gt 0) { 
        "{0:P2}" -f ($successCount / $totalCount) 
    } else { 
        "N/A" 
    }

    # Define the CSV file path for the specific VM
    $csvFilePath = Join-Path -Path $csvDirectoryPath -ChildPath ("VMHistoryReport_" + $vmNameInput + ".csv")

    # Export the session data to a CSV file
    $sessionData | Export-Csv -Path $csvFilePath -NoTypeInformation -Force -Delimiter ';'

    Write-Host "Backup session details for VM '$vmNameInput' have been saved to $csvFilePath"

    Write-Host "`nTotal Sessions for '$vmNameInput': $totalCount"
    Write-Host "Successful: $($successCount - $warningCount)"
    Write-Host "Warning: $warningCount"
    Write-Host "Failed: $failedCount"
    Write-Host "Success Rate: $successRate"
}

Read-Host -Prompt "Press Enter to exit"