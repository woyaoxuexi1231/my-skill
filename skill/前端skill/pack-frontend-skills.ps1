# Pack sibling skill folders into ./dist/
# Place this script NEXT TO skill folders, then run:
#   .\pack-frontend-skills.ps1 -Set curated -Zip
#   .\pack-frontend-skills.ps1 -Set all -Zip
#
# Layout:
#   any-folder/
#     pack-frontend-skills.ps1
#     INSTALL.md
#     prod-frontend/
#     frontend-creative-director/
#     ...

param(
  [ValidateSet("curated", "all")]
  [string]$Set = "curated",
  [switch]$Zip
)

$ErrorActionPreference = "Stop"

$skillsRoot = $PSScriptRoot
$stamp = Get-Date -Format "yyyyMMdd"
$outName = "$Set-$stamp"
$outDir = Join-Path $skillsRoot "dist\$outName"

$skipNames = @(
  "dist",
  "node_modules",
  ".git",
  ".cache"
)

# Curated stack for prod-frontend
$curated = @(
  "prod-frontend",
  "frontend-creative-director",
  "visual-critique",
  "impeccable",
  "taste-skill",
  "ui-ux-pro-max",
  "find-animation-opportunities",
  "improve-animations",
  "review-animations",
  "react-bits-guide"
)

function Get-SiblingSkillNames {
  Get-ChildItem -LiteralPath $skillsRoot -Directory |
    Where-Object { $skipNames -notcontains $_.Name } |
    Select-Object -ExpandProperty Name |
    Sort-Object
}

if ($Set -eq "curated") {
  $names = $curated
}
else {
  $names = Get-SiblingSkillNames
}

if (Test-Path -LiteralPath $outDir) {
  Remove-Item -LiteralPath $outDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$installSrc = Join-Path $skillsRoot "INSTALL.md"
if (Test-Path -LiteralPath $installSrc) {
  Copy-Item -LiteralPath $installSrc -Destination (Join-Path $outDir "INSTALL.md") -Force
}

$packScriptPath = $MyInvocation.MyCommand.Path
if (-not $packScriptPath) {
  $packScriptPath = Join-Path $skillsRoot "pack-frontend-skills.ps1"
}
Copy-Item -LiteralPath $packScriptPath -Destination (Join-Path $outDir "pack-frontend-skills.ps1") -Force

$packed = 0
foreach ($name in $names) {
  $src = Join-Path $skillsRoot $name
  if (-not (Test-Path -LiteralPath $src)) {
    Write-Warning "Missing skill folder: $name - skipped"
    continue
  }
  Copy-Item -LiteralPath $src -Destination (Join-Path $outDir $name) -Recurse -Force
  Write-Host "Packed $name"
  $packed++
}

$noise = @(
  (Join-Path $outDir "impeccable\node_modules"),
  (Join-Path $outDir "impeccable\.cache")
)
foreach ($p in $noise) {
  if (Test-Path -LiteralPath $p) {
    Remove-Item -LiteralPath $p -Recurse -Force
  }
}

Write-Host ""
Write-Host "Set: $Set | Count: $packed"
Write-Host "Output: $outDir"

if ($Zip) {
  $zipPath = Join-Path $skillsRoot "dist\$outName.zip"
  if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
  }
  Compress-Archive -Path (Join-Path $outDir "*") -DestinationPath $zipPath
  Write-Host "Zip: $zipPath"
}
