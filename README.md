# Veeam-Backup-Sessions-Report

Overview
This PowerShell script generates a detailed report of backup sessions for a specified job and VM using Veeam Backup and Replication cmdlets. It gathers data such as job name, VM name, job type, start time, average speed, duration, processed data, transferred data, result status, and provides a summary of total sessions, successful sessions, warnings, and failures.

Prerequisites
  PowerShell 5.0 or higher.
  Veeam Backup & Replication installed with access to the Veeam PowerShell module.
  Appropriate permissions to access Veeam backup jobs and sessions.

Usage
  - Modify the output file location.  `$txtFilePath`
  - Run the script in PowerShell.

Input Prompts
  The script will prompt you to enter the job name and the VM name.

Output
  The output will be saved to specified `$txtFilePath` location. By default, it is  "C:\temp\VMHistoryReport.txt" 

  Example Output:

Backup Session Report
===============================
Job Name                              VM Name                  Job Type       Start Time               Average Speed         Duration               Processed Data        Transferred Data      Result    
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ExampleJob                            VM1                      Full           2023-01-10 12:00:00      50.0 MB/s             00:30:00               20.00 GB              15.00 GB              Success    
...

Total Sessions: 5
Successful: 4
Warning: 1
Failed: 0
Success Rate: 80.00%
