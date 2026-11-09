#Requires -Version 5.1
<#
.SYNOPSIS
    Publish docs/wiki/{zh,en} to this repository's GitHub Wiki.

.DESCRIPTION
    GitHub Wiki pages live in a separate git repository (<repo>.wiki.git) and are
    flat files: Home.md, Getting-Started.md, ... plus one _Sidebar.md.

    This script maps the bilingual sources in this repository onto that layout:

        docs/wiki/zh/Home.md          -> Home.md
        docs/wiki/en/Home-EN.md       -> Home-EN.md
        docs/wiki/zh/_Sidebar.md  ┐
        docs/wiki/en/_Sidebar.md  ┴──> _Sidebar.md   (concatenated)

    The wiki repository only exists after the first page has been created in the
    GitHub web UI (Repository -> Wiki -> "Create the first page"). Push attempts
    before that fail with "Repository not found".

.PARAMETER WikiRepo
    Clone URL of the wiki repository. Defaults to the SSH URL of this project.

.PARAMETER OutputDir
    Only build the flat wiki layout into this directory, do not touch git.

.PARAMETER WorkDir
    Clone target when pushing. Defaults to a fresh temp directory.

.PARAMETER Message
    Commit message used for the push.

.EXAMPLE
    # Preview the generated layout without touching the network
    powershell -ExecutionPolicy Bypass -File ./scripts/sync-wiki.ps1 -OutputDir ./out/wiki

.EXAMPLE
    # Build the layout and push it to the GitHub Wiki
    powershell -ExecutionPolicy Bypass -File ./scripts/sync-wiki.ps1
#>
[CmdletBinding()]
param(
    [string]$WikiRepo = 'git@github.com:YUAXI/HomeAssistant-PWM-Fan-Controlx4.wiki.git',
    [string]$OutputDir,
    [string]$WorkDir = (Join-Path ([System.IO.Path]::GetTempPath()) ('wiki-sync-' + [guid]::NewGuid().ToString('N').Substring(0, 8))),
    [string]$Message = 'docs: sync wiki from docs/wiki',
    [switch]$NoPush,
    [switch]$Preview
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$Text) { Write-Host "==> $Text" -ForegroundColor Cyan }
function Write-Ok([string]$Text) { Write-Host "    $Text" -ForegroundColor Green }
function Write-Note([string]$Text) { Write-Host "    $Text" -ForegroundColor Yellow }
function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

# git writes progress/info to stderr, which PowerShell would turn into a
# terminating NativeCommandError under $ErrorActionPreference = 'Stop'.
# Route the output through 2>&1 and return the exit code instead.
# Call it as: Invoke-Git -GitArgs 'commit', '-m', $message
function Invoke-Git {
    param([string[]]$GitArgs)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & git @GitArgs 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prev
    }
    if ($output) { $output | Out-Host }
    return $code
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ZhDir = Join-Path $RepoRoot 'docs/wiki/zh'
$EnDir = Join-Path $RepoRoot 'docs/wiki/en'

if (-not (Test-Path $ZhDir)) { throw "Chinese wiki sources not found: $ZhDir" }
if (-not (Test-Path $EnDir)) { throw "English wiki sources not found: $EnDir" }

# ---------------------------------------------------------------- build layout
if ($OutputDir) {
    $Staging = $OutputDir
    if (Test-Path $Staging) { Remove-Item $Staging -Recurse -Force }
} else {
    $Staging = Join-Path $WorkDir 'layout'
}
New-Item -ItemType Directory -Force -Path $Staging | Out-Null

Write-Step 'Collecting pages'
$zhPages = @(Get-ChildItem $ZhDir -Filter *.md | Where-Object { $_.Name -ne '_Sidebar.md' } | Sort-Object Name)
$enPages = @(Get-ChildItem $EnDir -Filter *.md | Where-Object { $_.Name -ne '_Sidebar.md' } | Sort-Object Name)
if ($zhPages.Count -eq 0) { throw "No markdown pages in $ZhDir" }

foreach ($page in $zhPages) { Copy-Item $page.FullName (Join-Path $Staging $page.Name) -Force }
Write-Ok ("zh: {0} pages" -f $zhPages.Count)
foreach ($page in $enPages) { Copy-Item $page.FullName (Join-Path $Staging $page.Name) -Force }
Write-Ok ("en: {0} pages" -f $enPages.Count)

# ------------------------------------------------------------- missing pairs
$zhNames = @($zhPages | ForEach-Object { $_.BaseName })
$enNames = @($enPages | ForEach-Object { $_.BaseName })
foreach ($name in $zhNames) {
    if ($enNames -notcontains "$name-EN") { Write-Note "missing English page: en/$name-EN.md" }
}
foreach ($name in $enNames) {
    if ($zhNames -notcontains ($name -replace '-EN$', '')) { Write-Note "English page without Chinese source: en/$name.md" }
}

# ------------------------------------------------------------------- sidebar
Write-Step 'Building _Sidebar.md'
$sidebarParts = @()
foreach ($file in @((Join-Path $ZhDir '_Sidebar.md'), (Join-Path $EnDir '_Sidebar.md'))) {
    if (Test-Path $file) {
        $sidebarParts += ([System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)).Trim()
    } else {
        Write-Note "sidebar source missing: $file"
    }
}
$sidebarParts = @($sidebarParts | ForEach-Object { $_ -replace "`r`n", "`n" })
$sidebar = ($sidebarParts -join "`n`n---`n`n") + "`n"
if ($sidebar -match '[\uE000-\uF8FF]') {
    throw 'Sidebar contains private-use characters: a source file was read with the wrong encoding. ' +
          'Make sure docs/wiki/*/_Sidebar.md and this script are treated as UTF-8.'
}
Write-Utf8NoBom (Join-Path $Staging '_Sidebar.md') $sidebar
Write-Ok '_Sidebar.md written'

# --------------------------------------------------------------- link check
Write-Step 'Checking internal wiki links'
$available = @{}
foreach ($file in Get-ChildItem $Staging -Filter *.md) { $available[$file.BaseName] = $true }
$problems = 0
foreach ($file in Get-ChildItem $Staging -Filter *.md) {
    $text = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    foreach ($m in [regex]::Matches($text, '\]\((?<target>[^)\s#]+)(?<anchor>#[^)]*)?\)')) {
        $target = $m.Groups['target'].Value
        if ($target -match '^(https?:|mailto:|#|\./|\.\./)') { continue }
        if ($target -match '\.(png|jpg|jpeg|svg|zip|xlsx|STEP|step|epro2)$') { continue }
        $name = [System.IO.Path]::GetFileNameWithoutExtension($target)
        if (-not $available.ContainsKey($name)) {
            Write-Note ("{0}: unresolved link -> {1}" -f $file.Name, $target)
            $problems++
        }
    }
}
if ($problems -eq 0) { Write-Ok 'all internal links resolve' }
else { Write-Note ("{0} unresolved link(s) — GitHub Wiki will render them as 404" -f $problems) }

if ($OutputDir) {
    Write-Step "Layout written to $OutputDir"
    Get-ChildItem $Staging -Filter *.md | Select-Object -ExpandProperty Name | Sort-Object | ForEach-Object { Write-Ok $_ }
    return
}
if ($Preview) {
    Write-Step "Preview only — layout kept at $Staging, nothing pushed"
    return
}

# ------------------------------------------------------------- clone + push
$Checkout = Join-Path $WorkDir 'wiki'
Write-Step "Preparing wiki checkout in $Checkout"
if (-not (Test-Path (Join-Path $Checkout '.git'))) {
    $probe = git ls-remote $WikiRepo 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw @"
Wiki repository is not reachable: $WikiRepo
$probe

If git says "Repository not found", the wiki has not been initialised yet:
  1. open https://github.com/YUAXI/HomeAssistant-PWM-Fan-Controlx4/wiki
  2. click "Create the first page" and save any placeholder content
  3. re-run this script; it replaces the placeholder with docs/wiki/zh/Home.md
"@
    }
    if ((Invoke-Git -GitArgs 'clone', $WikiRepo, $Checkout) -ne 0) { throw "git clone failed: $WikiRepo" }
}
Push-Location $Checkout
try {
    $null = Invoke-Git -GitArgs 'pull', '--rebase'
    Write-Step 'Copying pages into the wiki checkout'
    Get-ChildItem $Checkout -Filter *.md | Remove-Item -Force
    Copy-Item (Join-Path $Staging '*.md') $Checkout -Force
    Write-Ok ("{0} files copied" -f (Get-ChildItem $Staging -Filter *.md).Count)

    $null = Invoke-Git -GitArgs 'add', '-A'
    $status = git status --porcelain
    if (-not $status) {
        Write-Step 'No changes to publish'
        return
    }
    if ((Invoke-Git -GitArgs 'commit', '-m', $Message) -ne 0) { throw 'git commit failed' }
    if ($NoPush) { Write-Step 'NoPush: commit created, not pushed'; return }
    if ((Invoke-Git -GitArgs 'push') -ne 0) { throw 'git push failed' }
    Write-Ok 'Wiki published'
} finally {
    Pop-Location
}
