param(
    [string]$Repo = 'Iron-Mark/Hackathon-FlowFit',
    [int]$PullRequest = 9,
    [string]$OutFile = 'build/release-status-snapshot.md',
    [switch]$SkipRemote,
    [switch]$SkipStrictAudit
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

function Invoke-NativeCapture {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $output = & $FilePath @Arguments 2>&1
    $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = (($output | Out-String).Trim())
    }
}

function Add-Line {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [AllowEmptyString()]
        [string]$Value
    )

    $Lines.Add($Value)
}

function Add-FencedBlock {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [string]$Language = 'text',
        [AllowEmptyString()]
        [string]$Value
    )

    Add-Line $Lines ('```' + $Language)
    if (-not [string]::IsNullOrWhiteSpace($Value)) {
        foreach ($line in ($Value -split "`r?`n")) {
            Add-Line $Lines $line
        }
    }
    Add-Line $Lines '```'
}

function Get-SummaryLine {
    param([string]$Output)

    $match = [regex]::Match($Output, 'Audit summary:\s*(?<summary>.+)$', 'Multiline')
    if ($match.Success) {
        return $match.Groups['summary'].Value.Trim()
    }
    return 'summary not available'
}

function Get-HttpStatus {
    param([string]$Url)

    if ([string]::IsNullOrWhiteSpace($Url)) {
        return 'not configured'
    }

    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 20
        return "HTTP $($response.StatusCode)"
    } catch {
        if ($_.Exception.Response) {
            return "HTTP $([int]$_.Exception.Response.StatusCode)"
        }
        return $_.Exception.Message
    }
}

Push-Location $repoRoot
try {
    $lines = New-Object System.Collections.Generic.List[string]
    $generatedAt = (Get-Date).ToUniversalTime().ToString('o')

    $branch = (Invoke-NativeCapture -FilePath 'git' -Arguments @('branch', '--show-current')).Output
    $commit = (Invoke-NativeCapture -FilePath 'git' -Arguments @('rev-parse', 'HEAD')).Output
    $status = (Invoke-NativeCapture -FilePath 'git' -Arguments @('status', '--short', '--branch')).Output
    $remoteUrl = (Invoke-NativeCapture -FilePath 'git' -Arguments @('remote', 'get-url', 'origin')).Output

    Add-Line $lines '# FlowFit Release Status Snapshot'
    Add-Line $lines ''
    Add-Line $lines ('- Generated: `{0}`' -f $generatedAt)
    Add-Line $lines ('- Repository: `{0}`' -f $repoRoot)
    Add-Line $lines ('- Branch: `{0}`' -f $branch)
    Add-Line $lines ('- Commit: `{0}`' -f $commit)
    Add-Line $lines ('- Origin: `{0}`' -f $remoteUrl)
    Add-Line $lines ''
    Add-Line $lines '## Local Git State'
    Add-Line $lines ''
    Add-FencedBlock -Lines $lines -Language 'text' -Value $status

    if ($SkipStrictAudit) {
        Add-Line $lines ''
        Add-Line $lines '## Strict Release Audit'
        Add-Line $lines ''
        Add-Line $lines '- Strict audit skipped by `-SkipStrictAudit`.'
    } else {
        $auditScript = Join-Path $repoRoot 'scripts/release_readiness_audit.ps1'
        $auditArgs = @('-NoProfile', '-File', $auditScript, '-Strict')
        if (-not [string]::IsNullOrWhiteSpace($Repo)) {
            $auditArgs += @('-GitHubRepo', $Repo)
        }
        $audit = Invoke-NativeCapture -FilePath 'pwsh' -Arguments $auditArgs
        Add-Line $lines ''
        Add-Line $lines '## Strict Release Audit'
        Add-Line $lines ''
        $auditSummary = Get-SummaryLine -Output $audit.Output
        Add-Line $lines ('- Exit code: `{0}`' -f $audit.ExitCode)
        Add-Line $lines ('- Summary: `{0}`' -f $auditSummary)
        Add-Line $lines ''
        Add-FencedBlock -Lines $lines -Language 'text' -Value $audit.Output
    }

    Add-Line $lines ''
    Add-Line $lines '## GitHub State'
    Add-Line $lines ''

    if ($SkipRemote) {
        Add-Line $lines '- Remote checks skipped by `-SkipRemote`.'
    } else {
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            Add-Line $lines '- GitHub CLI is not available.'
        } else {
            $pr = Invoke-NativeCapture -FilePath 'gh' -Arguments @(
                'pr',
                'view',
                [string]$PullRequest,
                '--repo',
                $Repo,
                '--json',
                'headRefOid,mergeStateStatus,isDraft,url,statusCheckRollup'
            )
            if ($pr.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($pr.Output)) {
                $prJson = $pr.Output | ConvertFrom-Json
                Add-Line $lines "- PR: $($prJson.url)"
                Add-Line $lines ('- PR draft: `{0}`' -f $prJson.isDraft)
                Add-Line $lines ('- PR merge state: `{0}`' -f $prJson.mergeStateStatus)
                Add-Line $lines ('- PR head: `{0}`' -f $prJson.headRefOid)
                Add-Line $lines ''
                Add-Line $lines '### PR Checks'
                Add-Line $lines ''
                foreach ($check in @($prJson.statusCheckRollup)) {
                    Add-Line $lines "- $($check.workflowName) / $($check.name): $($check.status) $($check.conclusion)"
                }
            } else {
                Add-Line $lines "- PR status unavailable: $($pr.Output)"
            }

            $variables = Invoke-NativeCapture -FilePath 'gh' -Arguments @(
                'variable',
                'list',
                '--repo',
                $Repo,
                '--json',
                'name,updatedAt'
            )
            Add-Line $lines ''
            Add-Line $lines '### Repository Variables'
            Add-Line $lines ''
            if ($variables.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($variables.Output)) {
                foreach ($variable in @($variables.Output | ConvertFrom-Json)) {
                    Add-Line $lines ('- `{0}` updated `{1}`' -f $variable.name, $variable.updatedAt)
                }
            } else {
                Add-Line $lines '- Repository variables unavailable.'
            }

            $pages = Invoke-NativeCapture -FilePath 'gh' -Arguments @(
                'api',
                "repos/$Repo/pages"
            )
            Add-Line $lines ''
            Add-Line $lines '### GitHub Pages'
            Add-Line $lines ''
            if ($pages.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($pages.Output)) {
                $pagesJson = $pages.Output | ConvertFrom-Json
                $pagesStatus = Get-HttpStatus -Url $pagesJson.html_url
                Add-Line $lines "- URL: $($pagesJson.html_url)"
                Add-Line $lines ('- Build type: `{0}`' -f $pagesJson.build_type)
                Add-Line $lines ('- Source branch: `{0}`' -f $pagesJson.source.branch)
                Add-Line $lines ('- HTTPS enforced: `{0}`' -f $pagesJson.https_enforced)
                Add-Line $lines ('- Live HTTP status: `{0}`' -f $pagesStatus)
            } else {
                Add-Line $lines "- Pages status unavailable: $($pages.Output)"
            }
        }
    }

    $outPath = if ([System.IO.Path]::IsPathRooted($OutFile)) {
        $OutFile
    } else {
        Join-Path $repoRoot $OutFile
    }
    $outDirectory = Split-Path -Parent $outPath
    if (-not [string]::IsNullOrWhiteSpace($outDirectory) -and -not (Test-Path -LiteralPath $outDirectory)) {
        New-Item -ItemType Directory -Path $outDirectory -Force | Out-Null
    }

    $lines -join [Environment]::NewLine | Set-Content -LiteralPath $outPath -Encoding utf8
    Write-Host "Release status snapshot written: $outPath"
    Write-Host 'RELEASE_STATUS_SNAPSHOT_WRITTEN'
}
finally {
    Pop-Location
}
