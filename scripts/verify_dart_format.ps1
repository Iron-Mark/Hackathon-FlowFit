param(
    [int]$ChunkSize = 60
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath

Push-Location $repoRoot
$formatExitCode = 0
try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'git is required to discover tracked Dart files.'
    }
    if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
        throw 'dart is required to run the formatter.'
    }
    if ($ChunkSize -lt 1) {
        throw 'ChunkSize must be at least 1.'
    }

    $files = @(git ls-files '*.dart')
    if ($files.Count -eq 0) {
        Write-Host 'No tracked Dart files found.'
        return
    }

    for ($i = 0; $i -lt $files.Count; $i += $ChunkSize) {
        $end = [Math]::Min($i + $ChunkSize - 1, $files.Count - 1)
        $chunk = $files[$i..$end]
        & dart format --output=none --set-exit-if-changed @chunk
        if ($LASTEXITCODE -ne 0) {
            $formatExitCode = $LASTEXITCODE
            break
        }
    }

    if ($formatExitCode -eq 0) {
        Write-Host "Dart format check passed for $($files.Count) tracked Dart files."
    }
} finally {
    Pop-Location
}

exit $formatExitCode
