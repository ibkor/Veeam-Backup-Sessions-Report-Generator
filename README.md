## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

# Veeam-Backup-Sessions-Report

Overview
These PowerShell scripts generates a detailed report of backup sessions for a specified VM using Veeam Backup and Replication cmdlets. It uses VM Name instead of vmID to gather data and provides historical data such as a summary of total sessions, successful sessions, warnings, and failures. If backup sessions from a specific job required, make the switch in the script. Enable two lines with the comment "#To be used only if a specific job required"

VMHistoryReport.ps1: prompts for a VM Name and generates txt file report for this specific VM.

VMHistoryReporttocsv.ps1: prompts for a VM Name and generates csv file report for this specific VM.

VMHistoryReportforMultipleVMs.ps1: reads Hostnames.txt file and generates csv reports for all the VMs in the file. 

VMHistoryReportforMultipleAgentServers.ps1: reads Hostnames.txt file and generates csv reports for all the agent servers in the file. 

Prerequisites
  - PowerShell 5.0 or higher.
  - Veeam Backup & Replication installed with access to the Veeam PowerShell module.
  - Appropriate permissions to access Veeam backup jobs and sessions.

Usage
  - Modify the output file location.  `$txtFilePath`
  - Run the script in PowerShell on Veeam Backup & Replication Server.
  - Format of Hostnames.txt is as below without any special characters:

    `VMName1`
    
     `VMName2`

     `VMName3
     .
     .`

Input Prompts
  - The script will prompt you to enter the VM name (and job name if enabled).

Output
  - The output will be saved to specified `$txtFilePath` location. By default, it is  "C:\temp\VMHistoryReport.txt" 

Disclaimer: The scripts in this repository are provided "as is" without any warranties, express or implied. The author is not liable for any damages resulting from the use or inability to use these scripts, including but not limited to direct, indirect, incidental, or consequential damages. Users accept full responsibility for any risks associated with using these scripts, including compliance with laws and regulations. By using these scripts, you agree to indemnify the author against any claims arising from your use.
