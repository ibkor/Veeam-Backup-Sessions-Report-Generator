# Veeam-Backup-Sessions-Report

Overview
This PowerShell script generates a detailed report of backup sessions for a specified job and VM using Veeam Backup and Replication cmdlets. It uses VM Name instead of vmID to gather data and provides historical data such as a summary of total sessions, successful sessions, warnings, and failures.

Prerequisites
  - PowerShell 5.0 or higher.
  - Veeam Backup & Replication installed with access to the Veeam PowerShell module.
  - Appropriate permissions to access Veeam backup jobs and sessions.

Usage
  - Modify the output file location.  `$txtFilePath`
  - Run the script in PowerShell on Veeam Backup & Replication Server.

Input Prompts
  - The script will prompt you to enter the job name and the VM name.

Output
  - The output will be saved to specified `$txtFilePath` location. By default, it is  "C:\temp\VMHistoryReport.txt" 

Disclaimer: The scripts in this repository are provided "as is" without any warranties, express or implied. The author is not liable for any damages resulting from the use or inability to use these scripts, including but not limited to direct, indirect, incidental, or consequential damages. Users accept full responsibility for any risks associated with using these scripts, including compliance with laws and regulations. By using these scripts, you agree to indemnify the author against any claims arising from your use.
