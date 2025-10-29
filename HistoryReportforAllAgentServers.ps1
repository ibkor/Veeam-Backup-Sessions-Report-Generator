$creds = Get-Credential
Connect-VBRServer -Credential $creds -Server "Your VBR Server Name"

$csvDirectoryPath = "C:\temp\VMHistoryReport\" # Output folder

$oneMonthAgo = (Get-Date).AddMonths(-1)

# Get all backup sessions from the last month
$allSessions = Get-VBRComputerBackupJobSession | Where-Object { $_.EndTime -ge $oneMonthAgo } | Sort-Object EndTimeUTC -Descending
Get-VBRComputerBackupJobSession | Where-Object { $_.EndTime -ge $oneMonthAgo } | Sort-Object EndTimeUTC -Descending
 
# Get all unique VM names from those sessions
$allVMNames = $allSessions | Get-VBRTaskSession | Select-Object -ExpandProperty Name | Sort-Object -Unique

# Prepare an array to hold all session details
$allSessionData = @()

$sessions = $allSessions | Get-VBRTaskSession -Name $allVMNames

foreach ($vmNameInput in $allVMNames) {
    # All backup task sessions for this specific VM from the last month
    $sessions = $allSessions | Get-VBRTaskSession -Name $vmNameInput

    foreach ($session in $sessions) {
        $jobname = $session.JobName
        $vmname = $session.Name 
        $duration = $session.Progress.Duration
        $starttime = $session.Progress.StartTimeLocal   
        $endtime = $session.Progress.StopTimeLocal       
        $transferreddata = "{0:N2} GB" -f ($session.Progress.TransferedSize / 1GB)       
        $type = if ($session.IsFullMode) { "Full" } else { "Incremental" }
        if ($session.JobSess.Name -like "*Synthetic*") { $type = "Synthetic Full" }
        $result = $session.Status

        $sessionDetails = [PSCustomObject]@{
            "Job Name"          = $jobname
            "Server Name"       = $vmname
            "Backup Type"       = $type
            "Start Time"        = $starttime   
            "End Time"          = $endtime
            "Duration"          = $duration              
            "Transferred Data"  = $transferreddata
            "Result"            = $result
        }

        $allSessionData += $sessionDetails
    }
}

# Define the CSV file path for the combined report
$csvFilePath = Join-Path -Path $csvDirectoryPath -ChildPath "VMHistoryReport_AllAgents.csv"

# Export the combined session data to a single CSV file
$allSessionData | Export-Csv -Path $csvFilePath -NoTypeInformation -Force -Delimiter ';'

Write-Host "Combined backup session details for all agent servers have been saved to $csvFilePath"
Read-Host -Prompt "Press Enter to exit" 
