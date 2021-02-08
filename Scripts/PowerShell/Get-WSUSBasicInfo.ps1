<#
 
.SYNOPSIS  
Collects basic information about the installed instance of WSUS Server

.DESCRIPTION 
Collects basic information about the installed instance of WSUS Server and generates two files:
COMPUTERNAME_WSUS_BasicInfo.txt
(Optional) COMPUTERNAME_WSUS_UpdateApprovals.txt

.PARAMETER GetApprovedUpdates
(Optional) Collects a list of updates approved in the last 90 days.

.PARAMETER OutputDirectory
(Optional) Specify the output directory. If this is blank, the current working directory location is used.

.PARAMETER SilentExecution
(Optional) Use this to prevent any messages from getting printed to the console host

.EXAMPLE 
Get-WsusBasicInfo

.NOTES
10/04/2016 - Version 1.0 - Initial Version of the script
Thanks to Vinay Pamnani for the script

#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false)]
    [switch]$GetApprovedUpdates,
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory,
    [Parameter(Mandatory = $false)]
    [switch]$SilentExecution
)

if (-not $OutputDirectory) {
    $OutputDirectory = $PWD.Path
}

$BasicOutputFile = Join-Path $OutputDirectory ($env:COMPUTERNAME + "_WSUS_BasicInfo.txt")
$ApprovalOutputFile = Join-Path $OutputDirectory ($env:COMPUTERNAME + "_WSUS_UpdateApprovals.txt")

$null | Out-File -FilePath $BasicOutputFile # Overwrite to empty file

if ($GetApprovedUpdates) {
    $null | Out-File -FilePath $ApprovalOutputFile # Overwrite to empty file
}

Function Write-Out {
    Param(
        [string] $text,
        [switch] $NoWriteHost,
        [switch] $IsErrorMessage,
        [string] $OutputFile
    )    

    if ($OutputFile -eq $null -or $OutputFile -eq "") {
        $OutputFile = $BasicOutputFile
    }

    $text | Out-File -FilePath $OutputFile -Append    
    
    if ($SilentExecution) {
        return
    }

    if (-not $NoWriteHost) {
        if ($IsErrorMessage) {
            Write-Host $text -ForegroundColor Red
        }
        else {
            Write-Host $text -ForegroundColor Cyan
        }
    }
}

Function Get-OSInfo() {
    Write-Out
    Write-Out "WSUS SERVER INFORMATION:"
    Write-Out
    Write-Out "Server Name: $env:COMPUTERNAME"
    Write-Out "Operating System: $([environment]::OSVersion)"
    Write-Out "WSUS Version: $($updateServer.Version)"
    Write-Out
    Write-Out "Date of Report: $(Get-Date)"
    Write-Out "User Running Report: $([environment]::UserDomainName)\$([environment]::UserName)"
}

Function Get-WSUSStatus() {
    Write-Out
    Write-Out "===="

    $status = $updateServer.GetStatus()
    Write-Out "  Updates: $($status.UpdateCount)"
    Write-Out "    Approved Updates: $($status.ApprovedUpdateCount)"
    Write-Out "    Not Approved Updates: $($status.NotApprovedUpdateCount)"
    Write-Out "    Declined Updates: $($status.DeclinedUpdateCount)"
    Write-Out "  Client Computer Count: $($status.ComputerTargetCount)"
    Write-Out "  Client Computers Needing Updates: $($status.ComputerTargetsNeedingUpdatesCount)"
    Write-Out "  Client Computers with Errors: $($status.ComputertargetsWithUpdateErrorsCount)"
    Write-Out "  Critical/Security Updates Not Approved: $($status.CriticalOrSecurityUpdatesNotApprovedForInstallCount)"
    Write-Out "  WSUS Infrastructure Updates Not Approved: $($status.WsusInfrastructureUpdatesNotApprovedForInstallCount)"
    Write-Out "  Number of Computer Target Groups: $($status.CustomComputerTargetGroupCount)"
    Write-Out "  Expired Updates: $($status.ExpiredUpdateCount)"
    Write-Out "  Updates Needed by Computers: $($status.UpdatesNeededByComputersCount)"
    Write-Out "  Updates Needing Files: $($status.UpdatesNeedingFilesCount)"
}

Function Get-ComponentsWithErrors {
    Write-Out
    Write-Out "===="
    Write-Out "COMPONENTS WITH ERRORS"
    Write-Out

    $componentsWithErrors = $updateServer.GetComponentsWithErrors()
    if ($componentsWithErrors.Count -gt 0) {
        foreach ($component in $componentsWithErrors) {
            Write-Out "  $component"
        }
    }
    else {
        Write-Out "  None."
    }
}

Function Get-WSUSConfiguration {
    Write-Out
    Write-Out "===="
    Write-Out "WSUS SERVER CONFIGURATION INFORMATION"    
    Write-Out

    $database = $updateServer.GetDatabaseConfiguration()    
    Write-Out "Database Settings"
    Write-Out "  Database Server: $($database.ServerName)"
    Write-Out "  Database Name: $($database.DatabaseName)"
    Write-Out "  Using Windows Internal Database: $($database.IsUsingWindowsInternalDatabase)"
    Write-Out

    $config = $updateServer.GetConfiguration()
    Write-Out "Proxy Settings:"
    Write-Out "  Use Proxy: $($config.UseProxy)"
    Write-Out "  Allow Proxy Credentials to be sent over non-SSL links: $($config.AllowProxyCredentialsOverNonSsl)"
    Write-Out "  Anonymous Proxy Access: $($config.AnonymousProxyAccess)"
    Write-Out "  Proxy Name: $($config.ProxyName)"
    Write-Out "  Proxy Server Port: $($config.ProxyServerPort)"
    Write-Out "  Proxy User Domain: $($config.ProxyUserDomain)"
    Write-Out "  Proxy User Name: $($config.ProxyUserName)"
    Write-Out "  Has Proxy Password: $($config.HasProxyPassword)"
    Write-Out

    $enabledLanguages = $config.GetEnabledUpdateLanguages()
    Write-Out "Updates Settings:"
    Write-Out "  Auto Approve WSUS Infrastructure Updates: $($config.AutoApproveWsusInfrastructureUpdates)"
    Write-Out "  Auto Refresh Update Approvals: $($config.AutoRefreshUpdateApprovals)"
    Write-Out "  Download Express Packages: $($config.DownloadExpressPackages)"
    Write-Out "  Download Update Binaries As Needed: $($config.DownloadUpdateBinariesAsNeeded)"
    Write-Out "  Host Binaries on Microsoft Update: $($config.HostBinariesOnMicrosoftUpdate)"
    Write-Out "  Local Content Cache Path: $($config.LocalContentCachePath)"
    Write-Out "  All Update Languages Enabled: $($config.AllUpdateLanguagesEnabled)"
    $temp = "  Enabled Update Languages:"
    foreach ($language in $enabledLanguages) {
        $temp = $temp + " $language"
    }
    Write-Out $temp
    Write-Out

    Write-Out "Synchronization Settings:"
    Write-Out "  Sync from Microsoft Update: $($config.SyncFromMicrosoftUpdate)"
    Write-Out "  Upstream WSUS Server Name: $($config.UpstreamWsusServerName)"
    Write-Out "  Upstream WSUS Server Port: $($config.UpstreamWsusServerPortNumber)"
    Write-Out "  Upstream WSUS Server, Use SSL: $($config.UpstreamWsusServerUseSsl)"
    Write-Out "  Is Replica Server: $($config.IsReplicaServer)"
    Write-Out
    
    Write-Out "Miscellaneous Settings:"
    Write-Out "  Client Event Expiration Time: $($config.ClientEventExpirationTime)"
    Write-Out "  Expired Event Detection Period: $($config.ExpiredEventDetectionPeriod)"
    Write-Out "  Last Configuration Change: $($config.LastConfigChange)"
    Write-Out "  Server Event Expiration Time: $($config.ServerEventExpirationTime)"
    Write-Out "  Server ID: $($config.ServerId)"
    Write-Out "  Targeting Mode: $($config.TargetingMode)"    
}

Function Get-SubscriptionList {
    Write-Out
    Write-Out "===="
    Write-Out "SUBSCRIPTIONS"    

    $subscription = $updateServer.GetSubscription()
    $categories = $subscription.GetUpdateCategories()
    $classifications = $subscription.GetUpdateClassifications()

    Write-Out
    Write-Out "  Update Categories:"
    Write-Out
    foreach ($category in $categories) {
        Write-Out "    $($category.Title)"
    }

    Write-Out
    Write-Out "  Update Classifications:"
    Write-Out
    foreach ($classification in $classifications) {
        Write-Out "    $($classification.Title)"
    }    
}

Function Get-SubscriptionInfo {
    Param(
        [int] $NumberOfDays
    )

    Write-Out
    Write-Out "===="
    Write-Out "WSUS SUBSCRIPTION INFORMATION"
    Write-Out

    $subscription = $updateServer.GetSubscription()
    $lastSyncInfo = $subscription.GetLastSynchronizationInfo()
    Write-Out "  Last synch start time: $($lastSyncInfo.StartTime)"
    Write-Out "  Last synch end time: $($lastSyncInfo.EndTime)"
    Write-Out "  Last synch error: $($lastSyncInfo.Error)"
    Write-Out "  Last synch error text: $($lastSyncInfo.ErrorText)"
    Write-Out "  Last synch result: $($lastSyncInfo.Result)"
    Write-Out "  Last synch was manual: $($lastSyncInfo.StartedManually)"

    $updateErrors = $lastSyncInfo.UpdateErrors
    if ($updateErrors.Count -lt 1) {
        Write-Out "  Last synch got all updates!"
    }
    else {
        Write-Out
        Write-Out "Last synch failed to get following updates:"
        foreach ($updateErrorInfo in $updateErrors) {
            $update = $updateServer.GetUpdate($updateErrorInfo.UpdateId)
            Write-Out "  Update ID: $($update.Title)"
            Write-Out "  Error: $($updateErrorInfo.Error)"
            Write-Out "  Error Text: $($updateErrorInfo.ErrorText)"
        }
    }

    $since = [DateTime]::Now.AddDays(-$NumberOfDays)
    Write-Out
    Write-Out "===="
    Write-Out "WSUS SUBSCRIPTION HISTORY FOR LAST $NumberOfDays DAYS (since $since):"
    Write-Out
    $eventHistory = $subscription.GetEventHistory($since, [DateTime]::Now)

    if ($eventHistory.Count -lt 1) {
        Write-Out "  None."
        return
    }

    foreach ($event in $eventHistory) {
        Write-Out "  $($event.CreationDate) - $($event.Message)"
    }
}

Function Get-ComputersNotCheckingIn {
    Param(
        [int] $NumberOfDays
    )

    $since = [DateTime]::Now.AddDays(-$NumberOfDays)
    Write-Out
    Write-Out "===="
    Write-Out "COMPUTERS THAT HAVE NOT CONTACTED THE WSUS SERVER FOR $NumberOfDays DAYS OR MORE (since $since):"
    Write-Out
    $computerTargets = $updateServer.GetComputerTargets()
    $count = 0
    foreach ($computerTarget in $computerTargets) {
        if ($computerTarget.LastReportedStatusTime -lt $since) {
            Write-Out "  $($computerTarget.FullDomainName) last checked in: $($computerTarget.LastReportedStatusTime)"
            $count++
        }
    }

    if ($count -eq 0) {
        Write-Out "  None."
    }
    else {
        Write-Out
        Write-Out "  Total: $count"
    }
}

Function Get-TargetGroupList {
    Param(
        [switch] $ListComputersInGroup
    )

    Write-Out
    Write-Out "===="

    if ($ListComputersInGroup) {
        Write-Out "CLIENT COMPUTER LIST"
    }
    else {
        Write-Out "COMPUTER TARGETING GROUPS"
    }

    Write-Out
    $computerTargetGroups = $updateServer.GetComputerTargetGroups()
    if ($computerTargetGroups.Count -lt 1) {
        Write-Out "  None."
        return
    }

    foreach ($targetGroup in $computerTargetGroups) {
        $targets = $targetGroup.GetComputerTargets()
        Write-Out "  ----"
        Write-Out "  Target Group: $($targetGroup.Name)"
        Write-Out "    Number of computers in group: $($targets.Count)"
        
        if ($ListComputersInGroup) {
            foreach ($computer in $targets) {
                $temp = "      Computer: $($computer.FullDomainName)`t"
                #$temp += " ($($computer.IPAddresss))"
                $temp += " LastStatus: $($computer.LastReportedStatusTime)"
                $temp += " LastSync: $($computer.LastSyncTime)"
                $temp += " (OS Build $($computer.OSInfo.Version.Build)"
                $temp += " Version $($computer.OSInfo.Version.Major).$($computer.OSInfo.Version.Minor) SP$($computer.OSInfo.Version.ServicePackMajor))"
                Write-Out $temp
            }
        }
        
        Write-Out
    }
}

Function Get-ApprovedUpdates {
    Param(
        [int] $NumberOfDays
    )

    $since = [DateTime]::Now.AddDays(-$NumberOfDays)

    Write-Out -OutputFile $ApprovalOutputFile
    Write-Out "====" -OutputFile $ApprovalOutputFile
    Write-Out "UPDATES (LATEST REVISION) APPROVED IN LAST $NumberOfDays DAYS (since $since)" -OutputFile $ApprovalOutputFile
    Write-Out -OutputFile $ApprovalOutputFile

    $updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
    $updateScope.FromArrivalDate = $since
    $updateScope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::LatestRevisionApproved
    $approvedUpdates = $updateServer.GetUpdateApprovals($updateScope)
    
    if ($approvedUpdates.Count -lt 1) {
        Write-Out "  None." -OutputFile $ApprovalOutputFile
        return
    }

    foreach ($updateApproval in $approvedUpdates) {
        $updateInfo = $updateServer.GetUpdate($updateApproval.UpdateId)
        Write-Out -OutputFile $ApprovalOutputFile
        Write-Out "Update ID: $($updateInfo.Id.UpdateId), Revision Number: $($updateInfo.Id.RevisionNumber), Title: $($updateInfo.Title)" -OutputFile $ApprovalOutputFile
        Write-Out "  Classification: $($updateInfo.UpdateClassificationTitle)" -OutputFile $ApprovalOutputFile
        Write-Out "  Action: $($updateApproval.Action), State: $($updateApproval.State), ComputerTargetGroup: $($updateApproval.GetComputerTargetGroup().Name)" -OutputFile $ApprovalOutputFile
        Write-Out "  ApprovalDate: $($updateApproval.CreationDate), GoLiveTime: $($updateApproval.GoLiveTime), Deadline: $($updateApproval.Deadline)" -OutputFile $ApprovalOutputFile
    }
}

# Main script

try {    
    
    [reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
    $updateServer = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer()
}
catch [Exception] {
    Write-Out
    Write-Out "  Failed to connect to the WSUS Server." -IsErrorMessage
    Write-Out "  Error: $($_.Exception.Message)" -IsErrorMessage
    Write-Out
    exit 2
}

try {

    Get-OSInfo
    Get-WSUSStatus
    Get-ComponentsWithErrors
    Get-WSUSConfiguration
    Get-SubscriptionList
    Get-SubscriptionInfo -NumberOfDays 7
    Get-ComputersNotCheckingIn -NumberOfDays 7
    Get-ComputersNotCheckingIn -NumberOfDays 30
    Get-TargetGroupList
    Get-TargetGroupList -ListComputersInGroup
    if ($GetApprovedUpdates) { Get-ApprovedUpdates -NumberOfDays 30 }    

}
catch [Exception] {
    Write-Out "An unexpected error occurred during execution." -IsErrorMessage
    Write-Out "Exception: $($_.Exception.Message)" -IsErrorMessage
    if ($_.Exception.ErrorRecord -ne $null) {
        if ((Get-Member -InputObject $_.Exception.ErrorRecord -Name ScriptStackTrace) -ne $null) {
            Write-Out "Stack Trace: " -IsErrorMessage
            Write-Out $($_.Exception.ErrorRecord.ScriptStackTrace) -IsErrorMessage
        }
    }
}

Write-Out
