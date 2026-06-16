param(
    [string]$Repo = 'Iron-Mark/Hackathon-FlowFit',
    [int]$PullRequest = 0,
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

function ConvertTo-SafeRemoteUrl {
    param([string]$Url)

    if ([string]::IsNullOrWhiteSpace($Url)) {
        return ''
    }

    $trimmed = $Url.Trim()

    try {
        $uri = [System.Uri]::new($trimmed)
        if ($uri.IsAbsoluteUri -and -not [string]::IsNullOrEmpty($uri.UserInfo)) {
            $builder = [System.UriBuilder]::new($uri)
            $builder.UserName = ''
            $builder.Password = ''
            return $builder.Uri.AbsoluteUri
        }
    } catch {
        # Fall through to scp-like git remote handling.
    }

    $scpLike = [regex]::Match($trimmed, '^(?<userinfo>[^@\s/]+)@(?<rest>[^:\s]+:.+)$')
    if ($scpLike.Success) {
        return $scpLike.Groups['rest'].Value
    }

    return $trimmed
}

function Add-RepositoryVariableReadiness {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [AllowNull()]
        [object[]]$Variables
    )

    $requiredNames = @(
        'FLOWFIT_PUBLIC_WEB_BASE_URL',
        'FLOWFIT_SUPPORT_EMAIL',
        'FLOWFIT_SUPPORT_EMAIL_VERIFIED',
        'SUPABASE_URL',
        'SUPABASE_PUBLISHABLE_KEY'
    )
    $optionalNames = @(
        'FLOWFIT_WEB_BASE_HREF'
    )

    $variablesByName = @{}
    foreach ($variable in @($Variables)) {
        $name = [string]$variable.name
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }
        $variablesByName[$name] = $variable
    }

    foreach ($name in $requiredNames) {
        if ($variablesByName.ContainsKey($name)) {
            $updatedAt = [string]$variablesByName[$name].updatedAt
            if ([string]::IsNullOrWhiteSpace($updatedAt)) {
                $updatedAt = 'unknown'
            }
            Add-Line $Lines ('- `{0}`: present, updated `{1}`' -f $name, $updatedAt)
        } else {
            Add-Line $Lines ('- `{0}`: missing' -f $name)
        }
    }

    foreach ($name in $optionalNames) {
        if ($variablesByName.ContainsKey($name)) {
            $updatedAt = [string]$variablesByName[$name].updatedAt
            if ([string]::IsNullOrWhiteSpace($updatedAt)) {
                $updatedAt = 'unknown'
            }
            Add-Line $Lines ('- `{0}`: optional override present, updated `{1}`' -f $name, $updatedAt)
        } else {
            Add-Line $Lines ('- `{0}`: optional override not set' -f $name)
        }
    }

    $knownNames = @($requiredNames + $optionalNames)
    $extraCount = @($variablesByName.Keys | Where-Object { $knownNames -notcontains $_ }).Count
    Add-Line $Lines ('- Additional repository variables: `{0}`' -f $extraCount)
}

Push-Location $repoRoot
try {
    $lines = New-Object System.Collections.Generic.List[string]
    $generatedAt = (Get-Date).ToUniversalTime().ToString('o')

    $branch = (Invoke-NativeCapture -FilePath 'git' -Arguments @('branch', '--show-current')).Output
    $commit = (Invoke-NativeCapture -FilePath 'git' -Arguments @('rev-parse', 'HEAD')).Output
    $status = (Invoke-NativeCapture -FilePath 'git' -Arguments @('status', '--short', '--branch')).Output
    $remoteUrl = ConvertTo-SafeRemoteUrl -Url ((Invoke-NativeCapture -FilePath 'git' -Arguments @('remote', 'get-url', 'origin')).Output)

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
            $prArgs = @(
                'pr',
                'view',
                '--repo',
                $Repo,
                '--json',
                'headRefOid,mergeStateStatus,isDraft,url,statusCheckRollup'
            )
            if ($PullRequest -gt 0) {
                $prArgs = @(
                    'pr',
                    'view',
                    [string]$PullRequest,
                    '--repo',
                    $Repo,
                    '--json',
                    'headRefOid,mergeStateStatus,isDraft,url,statusCheckRollup'
                )
            }

            $pr = Invoke-NativeCapture -FilePath 'gh' -Arguments $prArgs
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
                if ($PullRequest -gt 0) {
                    Add-Line $lines "- PR #$PullRequest status unavailable: $($pr.Output)"
                } else {
                    Add-Line $lines "- Current branch PR status unavailable: $($pr.Output)"
                }
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
            Add-Line $lines '### Repository Release Variables'
            Add-Line $lines ''
            if ($variables.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($variables.Output)) {
                try {
                    $variableObjects = @($variables.Output | ConvertFrom-Json)
                    Add-RepositoryVariableReadiness -Lines $lines -Variables $variableObjects
                } catch {
                    Add-Line $lines '- Repository variables output was not valid JSON.'
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
