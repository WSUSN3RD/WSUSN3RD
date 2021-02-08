 # Thanks to Vinay Pamnani for the script
 
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $True, Position = 1)]
    [string] $UpdateServer,
	
    [Parameter(Mandatory = $False)]
    [switch] $UseSSL,
	
    [Parameter(Mandatory = $True, Position = 2)]
    $Port,

    [Parameter(Mandatory = $False)]
    [switch] $Decline,

    [Parameter(Mandatory = $False)]
    [switch] $Delete,

    [Parameter(Mandatory = $False)]
    [switch] $SkipAdobe,

    [Parameter(Mandatory = $False)]
    [switch] $WhatIf

)

Write-Host ""

if (-not $WhatIf -and -not $Decline -and -not $Delete) {
    Write-Host "One of the following options must be specified: -Decline, -Delete OR -WhatIf"
    Write-Host "Example: .\Decline-ThirdPartyUpdates.ps1 -UpdateServer SERVERNAME.DOMAIN.COM -Port 8530 -WhatIf"
    Write-Host "Example: .\Decline-ThirdPartyUpdates.ps1 -UpdateServer SERVERNAME.DOMAIN.COM -Port 8530 -Decline"
    Write-Host "Example: .\Decline-ThirdPartyUpdates.ps1 -UpdateServer SERVERNAME.DOMAIN.COM -Port 8530 -Decline -SkipAdobe"
    exit
}

try {
    
    if ($UseSSL) {
        Write-Host "Connecting to WSUS server $UpdateServer on Port $Port using SSL... " -NoNewLine
    }
    Else {
        Write-Host "Connecting to WSUS server $UpdateServer on Port $Port... " -NoNewLine
    }
    
    [reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
    $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($UpdateServer, $UseSSL, $Port);
    $wsusconfig = $wsus.GetConfiguration()
    $tempPath = $wsusconfig.LocalContentCachePath
    $WSUSContent = Join-Path ($tempPath.SubString(0, $tempPath.LastIndexOf("\"))) "UpdateServicesPackages"
}
catch [System.Exception] {
    Write-Host "Failed to connect."
    Write-Host "Error:" $_.Exception.Message
    Write-Host "Please make sure that WSUS Admin Console is installed on this machine"
    Write-Host ""
    $wsus = $null
}

if ($wsus -eq $null) { return } 

Write-Host "Connected."
Write-Host "Getting a list of all third-party updates... " -NoNewLine

try {
    $updatescope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
    $updatescope.UpdateSources = [Microsoft.UpdateServices.Administration.UpdateSources]::Other
    
    $allUpdates = $wsus.GetUpdates($updatescope)
}

catch [System.Exception] {
    Write-Host "Failed to get updates."
    Write-Host "Error:" $_.Exception.Message    
    Write-Host ""
    return
}

Write-Host "Done"

Write-Host "Parsing the list of third-party updates... " -NoNewline

$countAllUpdates = 0
$countDeclined = 0
$countAdobe = 0
$count3rd = 0
$deleted = 0
$declined = 0

foreach ($update in $allUpdates) {
    
    $count3rd++    
    
    if ($update.IsDeclined) {
        $countDeclined++
    }
    
    if (@($update.CompanyTitles -like "Adobe*").Count -gt 0 -or @($update.ProductTitles -like "Adobe*").Count -gt 0) {
        $countAdobe++
    }    
}
$countToDecline = $count3rd - $countDeclined

Write-Host "Done."
Write-Host 
Write-Host "Found $count3rd third-party updates (including $countAdobe Adobe updates). $countDeclined are declined." -ForegroundColor Cyan

if ($WhatIf) {
    Write-Host "What-If: $countToDecline updates will be declined if -Decline switch is used." -ForegroundColor Yellow
    Write-Host "What-If: $count3rd updates will be deleted if -Delete switch is used.." -ForegroundColor Yellow    
}

if ($Decline -and -not $WhatIf) {
    Write-Host 
    Write-Host "Declining updates..."
    $i = 0
    foreach ($update in $allUpdates) {    
        if (-not $update.IsDeclined) {
            $i++
            #Write-Host "Declining update #$i $($update.Id.UpdateId.Guid)..."
            $percentComplete = "{0:N2}" -f (($i / $countToDecline) * 100)
            Write-Progress -Activity "Declining Updates" -Status "Declining update #$i/$countToDecline - $($update.Id.UpdateId.Guid)" -PercentComplete $percentComplete -CurrentOperation "$percentComplete% complete"
            try {
                if ($SkipAdobe -and (@($update.CompanyTitles -like "Adobe*").Count -gt 0 -or @($update.ProductTitles -like "Adobe*").Count -gt 0)) {
                    Write-Host "  Skipping Adobe update: $($update.Title)"                
                }
                else {
                    $update.Decline()
                    $declined++
                }                
            }
            catch [System.Exception] {
                Write-Host "Failed to delete $($update.Id.UpdateId.Guid). Error:" $_.Exception.Message
            }
        }
        else {
            Write-Host "  $($update.Id.UpdateId.Guid) is already declined. Skipped." 
        }
    }
    Write-Host "Declined $declined updates."
}

if ($Delete -and -not $WhatIf) {
    Write-Host 
    Write-Host "Deleting updates..."
    $i = 0
    foreach ($update in $allUpdates) {
        $i++
        #Write-Host "Deleting update #$i $($update.Id.UpdateId.Guid)..."
        $percentComplete = "{0:N2}" -f (($i / $count3rd) * 100)
        Write-Progress -Activity "Deleting Updates" -Status "Deleting update #$i/$count3rd - $($update.Id.UpdateId.Guid)" -PercentComplete $percentComplete -CurrentOperation "$percentComplete% complete"
        try {
            if ($SkipAdobe -and (@($update.CompanyTitles -like "Adobe*").Count -gt 0 -or @($update.ProductTitles -like "Adobe*").Count -gt 0)) {
                Write-Host "  Skipping Adobe update: $($update.Title)"                
            }
            else {
                $wsus.DeleteUpdate([Guid]($update.Id.UpdateId.Guid))
                $deleted++
                $updateContent = Join-Path $WSUSContent $($update.Id.UpdateId.Guid)
                $updateContentDeleted = Join-Path $WSUSContent "deleted.$($update.Id.UpdateId.Guid)"                
                if (Test-Path $updateContent) {
                    Rename-Item $updateContent -NewName "$($updateContentDeleted)"
                }
            }            
        }
        catch [System.Exception] {
            Write-Host "Failed to delete $($update.Id.UpdateId.Guid). Error:" $_.Exception.Message
        }        
    }
    Write-Host "Deleted $deleted updates."
}

Write-Host ""
