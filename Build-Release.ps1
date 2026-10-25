<#
.SYNOPSIS
    Packages BrandyTheme for a GitHub Release (zip + SHA-256 checksum).
    The in-app auto-updater REQUIRES both files to be attached to the release.

.EXAMPLE
    .\Build-Release.ps1
    # then on GitHub: create release tag v<version>, upload the two files from .\dist
#>
[CmdletBinding()]
param([string]$OutDir = (Join-Path $PSScriptRoot 'dist'))

$ErrorActionPreference = 'Stop'
$main = Join-Path $PSScriptRoot 'BrandyTheme.ps1'
$m = Select-String -Path $main -Pattern "AppVersion\s*=\s*'([^']+)'" | Select-Object -First 1
$version = $m.Matches[0].Groups[1].Value

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$zip = Join-Path $OutDir "BrandyTheme-$version.zip"
$files = 'BrandyTheme.ps1', 'Install-BrandyTheme.ps1', 'README.md', 'LICENSE' |
    ForEach-Object { Join-Path $PSScriptRoot $_ } | Where-Object { Test-Path -LiteralPath $_ }

if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path $files -DestinationPath $zip
$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLower()
"$hash  $(Split-Path $zip -Leaf)" | Set-Content -LiteralPath "$zip.sha256" -Encoding ASCII

Write-Host "Built $zip"
Write-Host "SHA-256 $hash"
Write-Host "Upload both files to a GitHub release tagged v$version."
