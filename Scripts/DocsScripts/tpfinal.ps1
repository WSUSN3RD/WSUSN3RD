#Requires -Version 7.0

# define parameters
param (
    [string] $relDate = $(throw "Release date parameter is required as 'mm/dd/yyyy'."),
    [switch] $dashTwo = $false # add this switch if it's the second release for the month, e.g., YYMM-2
)

# set variables
$dateObj = Get-Date ($relDate)
$yymm = $dateObj.ToString("yyMM")

if ( $dashTwo ) {
    $yymm = $yymm + "-2"
}
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$featureFilePath = "C:\Docs\Scripts\tpfeaturesfinal.txt"

# get feature list
$featureList = Import-Csv -Path $featureFilePath -Delimiter "`t"

# main list markdown
Write-Host "`nMarkdown for technical-preview.md:" -ForegroundColor Green
foreach ( $feature in $featureList )
{
    Write-Host "- [$($feature."Feature Name")]($($dateObj.year)/technical-preview-$yymm.md#$($feature.Anchor)) <!--$($feature.id)-->"
}

# release markdown
Write-Host "`nMarkdown for technical-preview-$yymm.md:" -ForegroundColor Green
foreach ( $feature in $featureList )
{
    Write-Host "[!INCLUDE [$($feature."Feature Name")](includes/$yymm/$($feature.ID).md)]"
}
