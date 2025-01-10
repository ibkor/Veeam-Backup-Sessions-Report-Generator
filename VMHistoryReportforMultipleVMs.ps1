# This project is licensed under the MIT License - see the LICENSE file for details.
 $csvDirectoryPath = "C:\temp\VMHistoryReport\" # Path to save the output. Only the folder this time as script will create several csv files for each VM in the hostnames file.
$HostnamesFilePath = "C:\temp\Hostnames.txt" # Path to the text file containing VM names. The format, each line will contain the VM name without any special character

# Read VM names from the text file
$vmNames = Get-Content -Path $HostnamesFilePath

foreach ($vmNameInput in $vmNames) {
    # All backup sessions for this specific VM
    $sessions = Get-VBRBackupSession | Sort-Object EndTimeUTC -Descending | Get-VBRTaskSession -Name $vmNameInput

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
