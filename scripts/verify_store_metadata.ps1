param(
    [switch]$Strict,
    [string]$OutFile = 'build/store-metadata-verification.json',
    [string]$PublicWebBaseUrl = '',
    [string]$SupportEmail = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$results = New-Object System.Collections.Generic.List[object]
$resolvedPublicWebBaseUrl = $PublicWebBaseUrl

function Add-Result {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PASS', 'WARN', 'FAIL')]
        [string]$Level,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Detail,
        [bool]$StrictFailure = $true
    )

    $effectiveLevel = $Level
    if ($Strict -and $Level -eq 'WARN' -and $StrictFailure) {
        $effectiveLevel = 'FAIL'
    }

    $script:results.Add([pscustomobject]@{
        level = $effectiveLevel
        name = $Name
        detail = $Detail
    })
}

function Add-Pass {
    param([string]$Name, [string]$Detail)
    Add-Result -Level 'PASS' -Name $Name -Detail $Detail
}

function Add-Warn {
    param([string]$Name, [string]$Detail, [bool]$StrictFailure = $true)
    Add-Result -Level 'WARN' -Name $Name -Detail $Detail -StrictFailure $StrictFailure
}

function Add-Fail {
    param([string]$Name, [string]$Detail)
    Add-Result -Level 'FAIL' -Name $Name -Detail $Detail
}

function Get-RepoPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return Join-Path $repoRoot $Path
}

function Read-RepoText {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = Get-RepoPath $Path
    if (-not (Test-Path -LiteralPath $fullPath)) {
        Add-Fail 'Required document' "Missing $Path."
        return ''
    }

    return Get-Content -Raw -LiteralPath $fullPath
}

function Get-MarkdownSection {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Heading
    )

    $pattern = '(?ms)^##\s+' + [regex]::Escape($Heading) + '\s*\r?\n(?<body>.*?)(?=^##\s+|\z)'
    $match = [regex]::Match($Content, $pattern)
    if ($match.Success) {
        return $match.Groups['body'].Value.Trim()
    }
    return ''
}

function Assert-TextLength {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Value,
        [int]$Min = 1,
        [int]$Max
    )

    $normalized = ($Value -replace '\s+', ' ').Trim()
    if ($normalized.Length -lt $Min) {
        Add-Fail $Name "Text is too short for store handoff: $($normalized.Length) characters."
    } elseif ($normalized.Length -gt $Max) {
        Add-Fail $Name "Text exceeds store handoff limit: $($normalized.Length)/$Max characters."
    } else {
        Add-Pass $Name "Text length is within expected bounds: $($normalized.Length)/$Max characters."
    }
}

function Assert-RequiredPhrases {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string[]]$Phrases
    )

    $normalizedContent = ConvertTo-NormalizedSearchText -Value $Content
    $missing = @()
    foreach ($phrase in $Phrases) {
        if (
            $Content.IndexOf($phrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0 -and
            -not $normalizedContent.Contains((ConvertTo-NormalizedSearchText -Value $phrase))
        ) {
            $missing += $phrase
        }
    }

    if ($missing.Count -eq 0) {
        Add-Pass $Name "Found required phrases: $($Phrases.Count)."
    } else {
        Add-Fail $Name "Missing required phrases: $($missing -join ', ')."
    }
}

function ConvertTo-NormalizedSearchText {
    param([Parameter(Mandatory = $true)][string]$Value)

    return (($Value.ToLowerInvariant() -replace '[^a-z0-9]+', ' ').Trim() -replace '\s+', ' ')
}

function Assert-Email {
    param([Parameter(Mandatory = $true)][string]$Value)

    if (
        [string]::IsNullOrWhiteSpace($Value) -or
        $Value -notmatch '^[A-Za-z0-9._+-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$' -or
        $Value -match 'YOUR_|REPLACE_WITH|<your-|example\.|invalid\.|\.test$|localhost'
    ) {
        Add-Fail 'Store support email' "Support email is missing, placeholder-shaped, or invalid: $Value"
    } else {
        Add-Pass 'Store support email' "Support email is syntactically valid: $Value"
    }
}

function Get-PngDimensions {
    param([Parameter(Mandatory = $true)][string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 24) {
        throw "PNG is too short: $Path"
    }

    $signature = @(137, 80, 78, 71, 13, 10, 26, 10)
    for ($i = 0; $i -lt $signature.Count; $i++) {
        if ($bytes[$i] -ne $signature[$i]) {
            throw "File is not a PNG: $Path"
        }
    }

    $width = (
        ([int64]$bytes[16] -shl 24) -bor
        ([int64]$bytes[17] -shl 16) -bor
        ([int64]$bytes[18] -shl 8) -bor
        [int64]$bytes[19]
    )
    $height = (
        ([int64]$bytes[20] -shl 24) -bor
        ([int64]$bytes[21] -shl 16) -bor
        ([int64]$bytes[22] -shl 8) -bor
        [int64]$bytes[23]
    )

    return [pscustomobject]@{
        width = [int]$width
        height = [int]$height
    }
}

function Test-PngDimension {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][int]$ExpectedWidth,
        [Parameter(Mandatory = $true)][int]$ExpectedHeight
    )

    $fullPath = Get-RepoPath $Path
    if (-not (Test-Path -LiteralPath $fullPath)) {
        Add-Fail $Name "Missing image asset: $Path"
        return
    }

    try {
        $dimensions = Get-PngDimensions -Path $fullPath
        if ($dimensions.width -eq $ExpectedWidth -and $dimensions.height -eq $ExpectedHeight) {
            Add-Pass $Name "$Path is ${ExpectedWidth}x${ExpectedHeight}."
        } else {
            Add-Fail $Name "$Path is $($dimensions.width)x$($dimensions.height), expected ${ExpectedWidth}x${ExpectedHeight}."
        }
    } catch {
        Add-Fail $Name $_.Exception.Message
    }
}

function Test-AndroidIcons {
    $expected = [ordered]@{
        'android/app/src/main/res/mipmap-mdpi/ic_launcher.png' = 48
        'android/app/src/main/res/mipmap-hdpi/ic_launcher.png' = 72
        'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png' = 96
        'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png' = 144
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png' = 192
    }

    foreach ($path in $expected.Keys) {
        Test-PngDimension -Name 'Android launcher icon' -Path $path -ExpectedWidth $expected[$path] -ExpectedHeight $expected[$path]
    }
}

function Convert-IconSizeToPixels {
    param(
        [Parameter(Mandatory = $true)][string]$Size,
        [Parameter(Mandatory = $true)][string]$Scale
    )

    $parts = $Size.Split('x')
    if ($parts.Count -ne 2) {
        throw "Invalid iOS icon size: $Size"
    }

    $multiplier = [int]($Scale.TrimEnd('x'))
    return [pscustomobject]@{
        width = [int]([double]$parts[0] * $multiplier)
        height = [int]([double]$parts[1] * $multiplier)
    }
}

function Test-IosIcons {
    $contentsPath = Get-RepoPath 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json'
    if (-not (Test-Path -LiteralPath $contentsPath)) {
        Add-Fail 'iOS app icon catalog' 'Missing iOS AppIcon Contents.json.'
        return
    }

    try {
        $catalog = Get-Content -Raw -LiteralPath $contentsPath | ConvertFrom-Json
    } catch {
        Add-Fail 'iOS app icon catalog' "Unable to parse Contents.json: $($_.Exception.Message)"
        return
    }

    $images = @($catalog.images | Where-Object { -not [string]::IsNullOrWhiteSpace($_.filename) })
    if ($images.Count -lt 1) {
        Add-Fail 'iOS app icon catalog' 'No concrete iOS icon filenames are listed.'
        return
    }

    Add-Pass 'iOS app icon catalog' "Catalog lists $($images.Count) concrete icon files."

    foreach ($image in $images) {
        $pixels = Convert-IconSizeToPixels -Size $image.size -Scale $image.scale
        $path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/' + $image.filename
        Test-PngDimension -Name 'iOS app icon' -Path $path -ExpectedWidth $pixels.width -ExpectedHeight $pixels.height
    }

    $marketingIcon = @($images | Where-Object { $_.idiom -eq 'ios-marketing' -and $_.size -eq '1024x1024' })
    if ($marketingIcon.Count -gt 0) {
        Add-Pass 'iOS marketing icon' 'Catalog includes a 1024x1024 ios-marketing icon.'
    } else {
        Add-Fail 'iOS marketing icon' 'Catalog must include a 1024x1024 ios-marketing icon for App Store Connect.'
    }
}

function Test-IosPrivacyManifest {
    $manifest = Read-RepoText 'ios/Runner/PrivacyInfo.xcprivacy'
    $pbxproj = Read-RepoText 'ios/Runner.xcodeproj/project.pbxproj'

    if ([string]::IsNullOrWhiteSpace($manifest)) {
        Add-Fail 'iOS privacy manifest' 'PrivacyInfo.xcprivacy must exist and must not be blank.'
    } else {
        try {
            [xml]$manifest | Out-Null
            Add-Pass 'iOS privacy manifest XML' 'PrivacyInfo.xcprivacy is valid XML.'
        } catch {
            Add-Fail 'iOS privacy manifest XML' "PrivacyInfo.xcprivacy is not valid XML: $($_.Exception.Message)"
        }

        Assert-RequiredPhrases -Name 'iOS privacy manifest declarations' -Content $manifest -Phrases @(
            'NSPrivacyAccessedAPITypes',
            'NSPrivacyAccessedAPICategoryUserDefaults',
            'CA92.1',
            'NSPrivacyAccessedAPICategoryFileTimestamp',
            'C617.1',
            'NSPrivacyCollectedDataTypes',
            'NSPrivacyCollectedDataTypeEmailAddress',
            'NSPrivacyCollectedDataTypeName',
            'NSPrivacyCollectedDataTypeUserID',
            'NSPrivacyCollectedDataTypeHealth',
            'NSPrivacyCollectedDataTypeFitness',
            'NSPrivacyCollectedDataTypePreciseLocation',
            'NSPrivacyCollectedDataTypePhotosorVideos',
            'NSPrivacyCollectedDataTypeOtherUserContent',
            'NSPrivacyCollectedDataTypeProductInteraction',
            'NSPrivacyCollectedDataTypePurposeAppFunctionality',
            'NSPrivacyTrackingDomains'
        )

        if ($manifest -match '(?ms)<key>NSPrivacyTracking</key>\s*<false\s*/>') {
            Add-Pass 'iOS privacy manifest tracking' 'PrivacyInfo.xcprivacy declares that the app does not track users.'
        } else {
            Add-Fail 'iOS privacy manifest tracking' 'PrivacyInfo.xcprivacy must set NSPrivacyTracking to false.'
        }

        if ($manifest -match '(?ms)<key>NSPrivacyTrackingDomains</key>\s*<array\s*/>') {
            Add-Pass 'iOS privacy manifest tracking domains' 'PrivacyInfo.xcprivacy declares no tracking domains.'
        } else {
            Add-Fail 'iOS privacy manifest tracking domains' 'PrivacyInfo.xcprivacy must keep NSPrivacyTrackingDomains empty unless tracking is intentionally introduced.'
        }
    }

    if (
        $pbxproj.Contains('PrivacyInfo.xcprivacy in Resources') -and
        $pbxproj.Contains('path = PrivacyInfo.xcprivacy')
    ) {
        Add-Pass 'iOS privacy manifest target resource' 'PrivacyInfo.xcprivacy is included in the Runner target resources.'
    } else {
        Add-Fail 'iOS privacy manifest target resource' 'PrivacyInfo.xcprivacy must be referenced by the Runner project and Resources build phase.'
    }
}

function Test-WebIcons {
    Test-PngDimension -Name 'Web icon' -Path 'web/icons/Icon-192.png' -ExpectedWidth 192 -ExpectedHeight 192
    Test-PngDimension -Name 'Web icon' -Path 'web/icons/Icon-512.png' -ExpectedWidth 512 -ExpectedHeight 512
    Test-PngDimension -Name 'Web maskable icon' -Path 'web/icons/Icon-maskable-192.png' -ExpectedWidth 192 -ExpectedHeight 192
    Test-PngDimension -Name 'Web maskable icon' -Path 'web/icons/Icon-maskable-512.png' -ExpectedWidth 512 -ExpectedHeight 512
    Test-PngDimension -Name 'Web favicon' -Path 'web/favicon.png' -ExpectedWidth 32 -ExpectedHeight 32
}

function Resolve-ExpectedWebUrls {
    $candidateBaseUrl = $script:resolvedPublicWebBaseUrl
    if ([string]::IsNullOrWhiteSpace($candidateBaseUrl)) {
        $candidateBaseUrl = [Environment]::GetEnvironmentVariable('FLOWFIT_PUBLIC_WEB_BASE_URL')
    }

    if ([string]::IsNullOrWhiteSpace($candidateBaseUrl)) {
        $script:resolvedPublicWebBaseUrl = ''
        return $null
    }

    $candidateBaseUrl = $candidateBaseUrl.Trim()

    try {
        $uri = [System.Uri]$candidateBaseUrl
        if ($uri.Scheme -ne 'https' -or [string]::IsNullOrWhiteSpace($uri.Host)) {
            Add-Fail 'Store public web URL' 'PublicWebBaseUrl must be a deployed HTTPS URL.'
            return $null
        }

        $origin = $uri.GetLeftPart([System.UriPartial]::Authority).TrimEnd('/')
        $path = $uri.AbsolutePath.TrimEnd('/')
        if ($path -eq '/') {
            $path = ''
        }
        $baseUrl = "$origin$path"
        $script:resolvedPublicWebBaseUrl = $baseUrl

        if (-not [string]::IsNullOrEmpty($uri.Query) -or -not [string]::IsNullOrEmpty($uri.Fragment)) {
            Add-Fail 'Store public web URL' "PublicWebBaseUrl must not contain a query or fragment. Parsed base URL: $baseUrl"
            return $null
        }

        return [pscustomobject]@{
            privacy = "$baseUrl/privacy.html"
            accountDeletion = "$baseUrl/account-deletion.html"
        }
    } catch {
        $script:resolvedPublicWebBaseUrl = ''
        Add-Fail 'Store public web URL' 'Unable to parse PublicWebBaseUrl as a deployed HTTPS URL.'
        return $null
    }
}

Push-Location $repoRoot
try {
    $metadata = Read-RepoText 'docs/STORE_METADATA_DRAFT.md'
    $privacyMap = Read-RepoText 'docs/PRIVACY_DATA_MAP.md'
    $checklist = Read-RepoText 'docs/STORE_SUBMISSION_CHECKLIST.md'

    foreach ($section in @(
        'Release Identity',
        'Short Description',
        'Full Description',
        'App Review Notes',
        'Screenshot Shot List',
        'Review Evidence Checklist',
        'Release Notes Draft'
    )) {
        if ([string]::IsNullOrWhiteSpace((Get-MarkdownSection -Content $metadata -Heading $section))) {
            Add-Fail 'Store metadata sections' "Missing ## $section in docs/STORE_METADATA_DRAFT.md."
        }
    }
    if (-not ($results | Where-Object { $_.name -eq 'Store metadata sections' -and $_.level -eq 'FAIL' })) {
        Add-Pass 'Store metadata sections' 'Store metadata draft includes the required handoff sections.'
    }

    $shortDescription = Get-MarkdownSection -Content $metadata -Heading 'Short Description'
    $fullDescription = Get-MarkdownSection -Content $metadata -Heading 'Full Description'
    $releaseNotes = Get-MarkdownSection -Content $metadata -Heading 'Release Notes Draft'
    Assert-TextLength -Name 'Store short description' -Value $shortDescription -Min 20 -Max 80
    Assert-TextLength -Name 'Store full description' -Value $fullDescription -Min 200 -Max 4000
    Assert-TextLength -Name 'Store release notes' -Value $releaseNotes -Min 20 -Max 500

    Assert-RequiredPhrases -Name 'Store full description claims' -Content $fullDescription -Phrases @(
        'workout tracking',
        'Wear OS',
        'heart-rate',
        'account deletion'
    )

    Assert-RequiredPhrases -Name 'Privacy data map coverage' -Content $privacyMap -Phrases @(
        'Account identifiers',
        'Profile data',
        'Workout data',
        'Heart-rate data',
        'Location data',
        'Camera/photo data',
        'Supabase',
        'Samsung Health Sensor API'
    )

    Assert-RequiredPhrases -Name 'Store checklist coverage' -Content $checklist -Phrases @(
        'Google Play',
        'App Store / TestFlight',
        'Flutter Web',
        'verify_support_inbox.ps1',
        'verify_web_deployment.ps1'
    )

    if ([string]::IsNullOrWhiteSpace($SupportEmail)) {
        $SupportEmail = [Environment]::GetEnvironmentVariable('FLOWFIT_SUPPORT_EMAIL')
    }
    if ([string]::IsNullOrWhiteSpace($SupportEmail)) {
        $SupportEmail = 'support@flowfit.com'
    }
    Assert-Email -Value $SupportEmail

    $expectedUrls = Resolve-ExpectedWebUrls
    if ($null -eq $expectedUrls) {
        Add-Warn 'Store public web URLs' 'FLOWFIT_PUBLIC_WEB_BASE_URL/PublicWebBaseUrl is not set; metadata still cannot be checked against deployed privacy and account-deletion URLs.'
    } else {
        if ($metadata.Contains($expectedUrls.privacy) -and $metadata.Contains($expectedUrls.accountDeletion)) {
            Add-Pass 'Store public web URLs' 'Metadata uses the configured deployed privacy and account-deletion URLs.'
        } else {
            Add-Warn 'Store public web URLs' "Metadata does not yet contain $($expectedUrls.privacy) and $($expectedUrls.accountDeletion)."
        }
    }

    $draftPatterns = @(
        '<your-web-host>',
        'provide after the production Supabase project exists',
        'Confirm ownership before release',
        'Draft handoff',
        '| Draft |',
        'Replace placeholders'
    )
    $draftHits = @()
    foreach ($pattern in $draftPatterns) {
        if ($metadata.Contains($pattern)) {
            $draftHits += $pattern
        }
    }
    if ($draftHits.Count -eq 0) {
        Add-Pass 'Store metadata finalization' 'No known draft placeholders remain in the store metadata draft.'
    } else {
        Add-Warn 'Store metadata finalization' "Draft placeholders remain: $($draftHits -join ', ')."
    }

    Test-AndroidIcons
    Test-IosIcons
    Test-IosPrivacyManifest
    Test-WebIcons

    $summary = [pscustomobject]@{
        pass = @($results | Where-Object { $_.level -eq 'PASS' }).Count
        warn = @($results | Where-Object { $_.level -eq 'WARN' }).Count
        fail = @($results | Where-Object { $_.level -eq 'FAIL' }).Count
    }

    $evidence = [pscustomobject]@{
        generatedAt = (Get-Date).ToUniversalTime().ToString('o')
        strict = [bool]$Strict
        publicWebBaseUrl = $resolvedPublicWebBaseUrl
        supportEmail = $SupportEmail
        summary = $summary
        results = @($results.ToArray())
    }

    $outPath = if ([System.IO.Path]::IsPathRooted($OutFile)) {
        [System.IO.Path]::GetFullPath($OutFile)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutFile))
    }
    $relativeOut = [System.IO.Path]::GetRelativePath($repoRoot, $outPath)
    if ($relativeOut.StartsWith('..') -or [System.IO.Path]::IsPathRooted($relativeOut)) {
        throw "OutFile must stay inside the repository: $OutFile"
    }

    $parent = Split-Path -Parent $outPath
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $evidence | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $outPath -Encoding utf8NoBOM

    Write-Host "Store metadata evidence written: $($relativeOut.Replace('\', '/'))"
    Write-Host "Audit summary: $($summary.pass) pass, $($summary.warn) warn, $($summary.fail) fail."
    Write-Host 'STORE_METADATA_VERIFICATION_WRITTEN'

    if ($summary.fail -gt 0) {
        exit 1
    }
    if ($summary.warn -gt 0) {
        exit 2
    }
} finally {
    Pop-Location
}
