# Downloads the General Sans font family from Fontshare into assets/fonts/GeneralSans/.
#
# The .otf files are not committed to this repository: General Sans ships under
# the Fontshare Free Font License, which permits embedding the fonts in the app
# but not redistributing the raw font files. Run this once after cloning (CI
# runs it automatically before build/test).
#
# Usage: pwsh scripts/fetch_fonts.ps1 [-Force]

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$fontDir = Join-Path $repoRoot 'assets/fonts/GeneralSans'
$downloadUrl = 'https://api.fontshare.com/v2/fonts/download/general-sans'

$expectedFonts = @(
    'GeneralSans-Extralight.otf',
    'GeneralSans-ExtralightItalic.otf',
    'GeneralSans-Light.otf',
    'GeneralSans-LightItalic.otf',
    'GeneralSans-Regular.otf',
    'GeneralSans-Italic.otf',
    'GeneralSans-Medium.otf',
    'GeneralSans-MediumItalic.otf',
    'GeneralSans-Semibold.otf',
    'GeneralSans-SemiboldItalic.otf',
    'GeneralSans-Bold.otf',
    'GeneralSans-BoldItalic.otf'
)

$missing = $expectedFonts | Where-Object { -not (Test-Path (Join-Path $fontDir $_)) }
if (-not $Force -and $missing.Count -eq 0) {
    Write-Host "All $($expectedFonts.Count) General Sans fonts already present in assets/fonts/GeneralSans/. Use -Force to re-download."
    exit 0
}

New-Item -ItemType Directory -Force $fontDir | Out-Null
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("general-sans-" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $tempDir | Out-Null
$zipPath = Join-Path $tempDir 'general-sans.zip'

try {
    Write-Host "Downloading General Sans from $downloadUrl ..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -MaximumRetryCount 3 -RetryIntervalSec 5

    Write-Host 'Extracting OTF files...'
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

    $otfSource = Get-ChildItem -Path $tempDir -Recurse -Filter '*.otf' |
        Where-Object { $_.FullName -match '[\\/]OTF[\\/]' }
    if ($otfSource.Count -eq 0) {
        throw 'No OTF files found in the downloaded archive; the Fontshare zip layout may have changed.'
    }

    foreach ($name in $expectedFonts) {
        $src = $otfSource | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        if (-not $src) {
            throw "Expected font '$name' was not found in the downloaded archive."
        }
        Copy-Item $src.FullName (Join-Path $fontDir $name) -Force
    }

    Write-Host "Installed $($expectedFonts.Count) General Sans fonts into assets/fonts/GeneralSans/."
}
finally {
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}
