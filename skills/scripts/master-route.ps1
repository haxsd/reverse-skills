# Thin master-route for haxsd/reverse-skills — bash ↔ pwsh aligned
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$Hint = ""
)

$ErrorActionPreference = 'Stop'

function Resolve-SkillRoot {
  if ($env:REVERSE_SKILL_ROOT) {
    $candidate = $env:REVERSE_SKILL_ROOT
    $reg = Join-Path $candidate 'skills/registry.json'
    if ((Test-Path -LiteralPath $candidate -PathType Container) -and (Test-Path -LiteralPath $reg -PathType Leaf)) {
      return (Resolve-Path -LiteralPath $candidate).Path
    }
    Write-Error "REVERSE_SKILL_ROOT is set but invalid: $candidate (need skills/registry.json)"
    exit 2
  }
  $here = $PSScriptRoot
  if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
  $candidate = (Resolve-Path -LiteralPath (Join-Path $here '../..')).Path
  $reg = Join-Path $candidate 'skills/registry.json'
  if (Test-Path -LiteralPath $reg -PathType Leaf) {
    return $candidate
  }
  Write-Error "cannot resolve skill root; set REVERSE_SKILL_ROOT or run from the cloned repo"
  exit 2
}

function Get-RouteFromHint([string]$RulesPath, [string]$HintText) {
  # Shared rules: skills/scripts/route-rules.tsv (same file as master-route.* / case-init.sh).
  # Priority: android > js (incl. Electron/ASAR) > packaged runtime → triage first > binary > default triage
  # Returns @(PRIMARY, REASON); first matching rule wins, case-insensitive (-match).
  if (-not (Test-Path -LiteralPath $RulesPath -PathType Leaf)) {
    Write-Error "routing rules missing: $RulesPath"
    exit 2
  }
  $h = $HintText.ToLowerInvariant()
  foreach ($line in [IO.File]::ReadAllLines($RulesPath, [Text.Encoding]::UTF8)) {
    if (-not $line -or $line.StartsWith('#')) { continue }
    $parts = $line.Split("`t", 3)
    if ($parts.Count -lt 3 -or -not $parts[2]) { continue }
    if ($h -match $parts[2]) { return @($parts[0], $parts[1]) }
  }
  return @('skills/triage/', 'default triage for unknown/general sample')
}

if (-not $Hint) {
  Write-Error "Usage: master-route.ps1 -Hint <task>"
  exit 2
}

$Root = Resolve-SkillRoot
$route = Get-RouteFromHint (Join-Path $Root 'skills/scripts/route-rules.tsv') $Hint
$primary = $route[0]
$reason = $route[1]

$primaryAbs = Join-Path $Root ($primary -replace '/', [IO.Path]::DirectorySeparatorChar)
if (-not $primaryAbs.EndsWith([IO.Path]::DirectorySeparatorChar)) {
  $primaryAbs = $primaryAbs + [IO.Path]::DirectorySeparatorChar
}
$skillMd = Join-Path $primaryAbs 'SKILL.md'
if (-not (Test-Path -LiteralPath $skillMd -PathType Leaf)) {
  Write-Error "PRIMARY skill missing: $skillMd"
  exit 2
}

# Keep PRIMARY with forward slashes for cross-platform agent contracts
$primaryOut = $primary -replace '\\', '/'
Write-Output "ROOT=$Root"
Write-Output "PRIMARY=$primaryOut"
Write-Output "PRIMARY_ABS=$primaryAbs"
Write-Output "REASON=$reason"
Write-Output "HINT=$Hint"
Write-Output "NEXT=Read $skillMd after case-init scope is ready"
