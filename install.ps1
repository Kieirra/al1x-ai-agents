#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Claude,
    [switch]$Codex,
    [switch]$All,
    [switch]$Local,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$Repo = "Kieirra/al1x-ai-agents"
$Branch = "main"
$ArchiveUrl = "https://github.com/$Repo/archive/refs/heads/$Branch.zip"

# Commandes livrées par les anciennes versions, désormais migrées en skills.
$LegacyClaudeCommands = @("archive-us", "commit", "create-pr", "list-us", "team", "update-agents", "workflow")

function Write-Info    { param($m) Write-Host "[INFO] $m"   -ForegroundColor Blue }
function Write-Ok      { param($m) Write-Host "[OK] $m"     -ForegroundColor Green }
function Write-WarnMsg { param($m) Write-Host "[WARN] $m"   -ForegroundColor Yellow }
function Write-ErrMsg  { param($m) Write-Host "[ERREUR] $m" -ForegroundColor Red }

function Fail {
    param($m)
    Write-ErrMsg $m
    exit 1
}

function Show-Usage {
    @"
Usage: install.ps1 [-Claude|-Codex|-All] [-Local]

Plateforme :
  -Claude  Installe les agents et skills Claude Code (defaut)
  -Codex   Installe les agents et skills Codex
  -All     Installe Claude Code et Codex

Portee :
  (defaut) Installation globale dans les dossiers utilisateur
  -Local   Installation dans le projet courant
"@ | Write-Host
}

if ($Help) {
    Show-Usage
    exit 0
}

$installClaude = $false
$installCodex = $false
$platformSelected = $false

if ($Claude) { $installClaude = $true; $platformSelected = $true }
if ($Codex)  { $installCodex  = $true; $platformSelected = $true }
if ($All)    { $installClaude = $true; $installCodex = $true; $platformSelected = $true }

# Retrocompatibilite : sans option de plateforme, conserver l'installation Claude.
if (-not $platformSelected) { $installClaude = $true }

$installMode = if ($Local) { "local" } else { "global" }

$script:TempDir = $null

function Resolve-Source {
    if ($env:AL1X_SOURCE_DIR) {
        if (-not (Test-Path (Join-Path $env:AL1X_SOURCE_DIR "claude"))) { Fail "AL1X_SOURCE_DIR ne contient pas claude/." }
        if (-not (Test-Path (Join-Path $env:AL1X_SOURCE_DIR "codex")))  { Fail "AL1X_SOURCE_DIR ne contient pas codex/." }
        return (Resolve-Path $env:AL1X_SOURCE_DIR).Path
    }

    $script:TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("al1x-" + [System.Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $script:TempDir -Force | Out-Null

    $zipPath = Join-Path $script:TempDir "source.zip"
    Write-Info "Telechargement de $Repo@$Branch..."
    try {
        Invoke-WebRequest -Uri $ArchiveUrl -OutFile $zipPath -UseBasicParsing
    } catch {
        Fail "Impossible de telecharger l'archive GitHub."
    }

    Expand-Archive -Path $zipPath -DestinationPath $script:TempDir -Force
    $repoName = ($Repo -split "/")[-1]
    $sourceRoot = Join-Path $script:TempDir "$repoName-$Branch"
    if (-not (Test-Path (Join-Path $sourceRoot "claude"))) { Fail "Archive GitHub invalide : claude/ absent." }
    if (-not (Test-Path (Join-Path $sourceRoot "codex")))  { Fail "Archive GitHub invalide : codex/ absent." }
    return $sourceRoot
}

function Sync-Directory {
    param(
        [string]$SourceDir,
        [string]$TargetDir,
        [string]$Label
    )

    if (-not (Test-Path $SourceDir)) { Fail "Source absente : $SourceDir" }
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

    $manifest = Join-Path $TargetDir ".al1x-ai-agents.manifest"

    if (Test-Path $manifest) {
        foreach ($name in (Get-Content -LiteralPath $manifest)) {
            if ([string]::IsNullOrWhiteSpace($name)) { continue }
            $srcItem = Join-Path $SourceDir $name
            $dstItem = Join-Path $TargetDir $name
            if ((-not (Test-Path $srcItem)) -and (Test-Path $dstItem)) {
                Remove-Item -LiteralPath $dstItem -Recurse -Force
                Write-WarnMsg "$Label obsolete supprime : $name"
            }
        }
    }

    $names = New-Object System.Collections.Generic.List[string]
    $count = 0
    foreach ($item in (Get-ChildItem -LiteralPath $SourceDir)) {
        $name = $item.Name
        $dstItem = Join-Path $TargetDir $name
        if (Test-Path $dstItem) { Remove-Item -LiteralPath $dstItem -Recurse -Force }
        Copy-Item -LiteralPath $item.FullName -Destination $dstItem -Recurse -Force
        $names.Add($name)
        $count++
    }

    Set-Content -LiteralPath $manifest -Value $names -Encoding utf8
    Write-Ok "$Label : $count element(s) installe(s) dans $TargetDir"
}

function Set-CodexConfig {
    param([string]$ConfigFile)

    $dir = Split-Path -Parent $ConfigFile
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    if (-not (Test-Path $ConfigFile)) {
        Set-Content -LiteralPath $ConfigFile -Value "[agents]`nmax_depth = 2`nmax_threads = 8" -Encoding utf8
        Write-Ok "Configuration Codex creee : $ConfigFile"
        return
    }

    $lines = @(Get-Content -LiteralPath $ConfigFile)
    $hasAgents = $lines | Where-Object { $_ -match '^\[agents\]\s*$' }

    $out = New-Object System.Collections.Generic.List[string]

    if (-not $hasAgents) {
        $out.Add("[agents]")
        $out.Add("max_depth = 2")
        $out.Add("max_threads = 8")
        $out.Add("")
        foreach ($l in $lines) { $out.Add($l) }
    } else {
        $inAgents = $false
        $depthSeen = $false
        $threadsSeen = $false

        function Get-TomlValue {
            param([string]$line)
            $v = $line -replace '.*=', ''
            $v = $v -replace '\s*#.*', ''
            return $v.Trim()
        }

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]

            if ($line -match '^\[agents\]\s*$') {
                $inAgents = $true
                $out.Add($line)
                continue
            }

            if ($line -match '^\[') {
                if ($inAgents) {
                    if (-not $depthSeen)   { $out.Add("max_depth = 2") }
                    if (-not $threadsSeen) { $out.Add("max_threads = 8") }
                }
                $inAgents = $false
                $out.Add($line)
                continue
            }

            if ($inAgents -and $line -match '^\s*max_depth\s*=') {
                $value = Get-TomlValue $line
                if ([int]$value -lt 2) { $out.Add("max_depth = 2") } else { $out.Add($line) }
                $depthSeen = $true
                continue
            }

            if ($inAgents -and $line -match '^\s*max_threads\s*=') {
                $value = Get-TomlValue $line
                if ([int]$value -lt 8) { $out.Add("max_threads = 8") } else { $out.Add($line) }
                $threadsSeen = $true
                continue
            }

            $out.Add($line)
        }

        if ($inAgents) {
            if (-not $depthSeen)   { $out.Add("max_depth = 2") }
            if (-not $threadsSeen) { $out.Add("max_threads = 8") }
        }
    }

    Set-Content -LiteralPath $ConfigFile -Value $out -Encoding utf8
    Write-Ok "Configuration Codex synchronisee : max_depth>=2, max_threads>=8"
}

function Invoke-LegacyClaudeMigration {
    param([string]$BaseDir)

    $commandsDir = Join-Path $BaseDir "commands"
    if (-not (Test-Path $commandsDir)) { return }

    $removed = 0
    foreach ($name in $LegacyClaudeCommands) {
        $file = Join-Path $commandsDir "$name.md"
        if (Test-Path $file) {
            Remove-Item -LiteralPath $file -Force
            $removed++
        }
    }

    if ($removed -gt 0) {
        Write-WarnMsg "Anciennes commandes Claude supprimees : $removed (migrees en skills)"
    }

    if ((Test-Path $commandsDir) -and (-not (Get-ChildItem -LiteralPath $commandsDir -Force))) {
        Remove-Item -LiteralPath $commandsDir -Force
    }
}

function Install-Claude {
    param([string]$SourceRoot)

    if ($installMode -eq "local") {
        $baseDir = ".claude"
    } else {
        $baseDir = Join-Path $HOME ".claude"
    }

    Write-Info "Installation Claude Code ($installMode)..."
    Invoke-LegacyClaudeMigration -BaseDir $baseDir
    Sync-Directory (Join-Path $SourceRoot "claude/agents") (Join-Path $baseDir "agents") "Agents Claude"
    Sync-Directory (Join-Path $SourceRoot "claude/skills") (Join-Path $baseDir "skills") "Skills Claude"
    Sync-Directory (Join-Path $SourceRoot "resources")     (Join-Path $baseDir "resources") "Ressources Claude"
}

function Install-Codex {
    param([string]$SourceRoot)

    if ($installMode -eq "local") {
        $codexDir = ".codex"
        $skillsDir = ".agents/skills"
    } else {
        $codexDir = Join-Path $HOME ".codex"
        $skillsDir = Join-Path $HOME ".agents/skills"
    }

    Write-Info "Installation Codex ($installMode)..."
    Sync-Directory (Join-Path $SourceRoot "codex/agents") (Join-Path $codexDir "agents") "Agents Codex"
    Sync-Directory (Join-Path $SourceRoot "codex/skills") $skillsDir "Skills Codex"
    Sync-Directory (Join-Path $SourceRoot "resources")    (Join-Path $codexDir "resources") "Ressources Codex"
    Set-CodexConfig (Join-Path $codexDir "config.toml")
}

try {
    if (-not (Get-Command Expand-Archive -ErrorAction SilentlyContinue)) {
        Fail "Expand-Archive est requis (PowerShell 5.1+)."
    }

    $sourceRoot = Resolve-Source

    if ($installClaude) { Install-Claude -SourceRoot $sourceRoot }
    if ($installCodex)  { Install-Codex -SourceRoot $sourceRoot }

    Write-Host ""
    Write-Ok "Installation terminee."
    if ($installClaude) {
        Write-Info "Claude : utilise /team, /architecte, /dev ou /update-agents."
    }
    if ($installCodex) {
        Write-Info "Codex : utilise `$team, `$architecte, `$dev ou `$update-agents."
        Write-Info "Ouvre une nouvelle session Codex pour recharger les agents et la configuration."
    }
} finally {
    if ($script:TempDir -and (Test-Path $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
