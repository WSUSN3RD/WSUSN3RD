#Requires -Version 7.0

# define parameters
param (
    [string] $relDate = $(throw "Release date parameter is required as 'mm/dd/yyyy'."),
    [switch] $dashTwo = $false, # add this switch if it's the second release for the month, e.g., YYMM-2
    [switch] $test = $false # add this switch while testing to NOT create any files
)

# set variables
$dateObj = Get-Date ($relDate)
$yymm = $dateObj.ToString("yyMM")

if ( $dashTwo ) {
    $yymm = $yymm + "-2"
}

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$featureFilePath = "C:\Docs\Scripts\tpfeatures.txt"
$repoPath = "C:\Program Files\Git\memdocs-pr\memdocs\configmgr\"
$tpPath = $repoPath + "core\get-started\" + $dateObj.year + "\includes\"

# get feature list
$featureList = Import-Csv -Path $featureFilePath -Delimiter "`t"

# main list markdown
Write-Host "`nMarkdown for technical-preview.md:" -ForegroundColor Green
foreach ( $feature in $featureList )
{
    Write-Host "- [$($feature.id)]($($dateObj.year)/technical-preview-$yymm.md) <!--$($feature.id)-->"
}

# release markdown
Write-Host "`nMarkdown for technical-preview-$yymm.md:" -ForegroundColor Green
foreach ( $feature in $featureList )
{
    Write-Host "[!INCLUDE [$($feature.id)](includes/$yymm/$($feature.id).md)]"
}

# include files
$dir = $tpPath + $yymm

If ( !$test ) {
    Write-Host "`nCreating directory at $($dir)..." -ForegroundColor Green
    $releasePath = New-Item -Path $dir -ItemType "directory"
} else {
    Write-Host "`nTEST directory path: $($dir)" -ForegroundColor Yellow
}

If ( $releasePath ) {

$includeTemplate = @"
---
author: mestew
ms.author: mstewart
ms.prod: configuration-manager
ms.technology: configmgr-core
ms.topic: include
ms.date: $($dateObj.ToString("MM/dd/yyyy"))
ms.localizationpriority: medium
---

## <a name="bkmk_anchor"></a> Feature Name
<!--CMADO#-->

"@

Write-Host "`nCreating blank include files at $($releasePath.FullName)..." -ForegroundColor Green

foreach ( $feature in $featureList )
{
    $file = $releasePath.FullName + "\" + $feature.ID + ".md"
    Write-Host $file
    $includeTemplate | Out-File -FilePath $file -Encoding utf8NoBOM
}

} else {
    Write-Host "Files not created because the path was blank" -ForegroundColor Red
}