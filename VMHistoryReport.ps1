# This project is licensed under the MIT License - see the LICENSE file for details.
 $txtFilePath = "C:\temp\VMHistoryReport.txt" #Path to save the output

#To be used only if a specific job required
#$jobNameInput = Read-Host -Prompt "Please enter the Job name"

$vmNameInput = Read-Host -Prompt "Please enter the VM name"

# Retrieve the job and corresponding sessions, if a specific job required
#$job = Get-VBRJob -Name $jobNameInput
#$sessions = Get-VBRBackupSession | Where-Object {$_.jobId -eq $job.Id.Guid} | Sort-Object EndTimeUTC -Descending | Get-VBRTaskSession -Name $vmNameInput

#all backup sessions for this specific VMs
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

$content = @"
Backup Session Report
===============================
"@

$header = "{0,-40} {1,-25} {2,-15} {3,-25} {4,-25} {5,-15} {6,-20} {7,-20} {8,-10}" -f `
           "Job Name", "VM Name", "Job Type", "Start Time", "Average Speed", "Duration", "Processed Data", "Transferred Data", "Result"

$content += "`n" + $header + "`n"
$content += ("-" * 200) + "`n"

foreach ($session in $sessionData) {
    $sessionOutput = "{0,-40} {1,-25} {2,-15} {3,-25} {4,-25} {5,-15} {6,-20} {7,-20} {8,-10}" -f `
                    $session.'Job Name', 
                    $session.'VM Name', 
                    $session.'Job Type', 
                    $session.'Start Time', 
                    $session.'Average Speed', 
                    $session.'Duration', 
                    $session.'Processed Data', 
                    $session.'Transferred Data', 
                    $session.'Result'

    Write-Host $sessionOutput
    
    $content += $sessionOutput + "`n"
}

$content += "`nTotal Sessions: $totalCount`n"
$content += "Successful: $($successCount - $warningCount)`n"
$content += "Warning: $warningCount`n"
$content += "Failed: $failedCount`n"
$content += "Success Rate: $successRate`n"

Write-Host "`nTotal Sessions: $totalCount"
Write-Host "Successful: $($successCount - $warningCount)"
Write-Host "Warning: $warningCount"
Write-Host "Failed: $failedCount"
Write-Host "Success Rate: $successRate"

Set-Content -Path $txtFilePath -Value $content

Write-Host "Backup session details have been saved to $txtFilePath"

Read-Host -Prompt "Press Enter to exit"
