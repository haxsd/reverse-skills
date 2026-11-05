# Thin case-init for haxsd/reverse-skills — auth gate aware; bash ↔ pwsh aligned
[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)][string]$Hint,
  [Parameter(Mandatory = $false)][string]$CaseName,
  [string]$Preset = "",
  [string]$Sample = "",
  [string]$ProjectRoot = "",
  [switch]$AuthGranted,
  [string]$NetworkProfile = "lab_only",
  [string]$AuthBasis = "unknown",
  [string]$EvidenceOfAuth = ""
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

function Write-Utf8NoBom([string]$Path, [string]$Content) {
  $enc = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

if (-not $Hint -or -not $CaseName) {
  Write-Error "Usage: case-init.ps1 -Hint TEXT -CaseName NAME [-Preset offline-sample -Sample FILE]"
  exit 2
}

$Root = Resolve-SkillRoot
if (-not $ProjectRoot) {
  $ProjectRoot = (Get-Location).Path
} else {
  if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
    Write-Error "ProjectRoot not a directory: $ProjectRoot"
    exit 2
  }
  $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
}

$authStatus = if ($AuthGranted) { "granted" } else { "pending" }
$network = $NetworkProfile
$basis = $AuthBasis
$evidence = $EvidenceOfAuth
$samplePath = ""

switch ($Preset) {
  { $_ -in @("offline-sample","own-sample","local-sample") } {
    if (-not $Sample) {
      Write-Error "offline-sample preset requires -Sample"
      exit 2
    }
    if (-not (Test-Path -LiteralPath $Sample -PathType Leaf)) {
      Write-Error "sample not found: $Sample"
      exit 2
    }
    $authStatus = "granted"
    $basis = "own_system"
    $network = "offline"
    if (-not $evidence) { $evidence = "preset:offline-sample (owner-operated local file)" }
    $samplePath = (Resolve-Path -LiteralPath $Sample).Path
  }
  { $_ -in @("ctf-public","ctf") } {
    $authStatus = "granted"
    $basis = "ctf_public"
    if (-not $network) { $network = "lab_only" }
    if (-not $evidence) { $evidence = "preset:ctf-public" }
  }
  "" { }
  default { Write-Error "unknown preset: $Preset"; exit 2 }
}

$caseDir = Join-Path $ProjectRoot (Join-Path 'work' $CaseName)
New-Item -ItemType Directory -Force -Path (Join-Path $caseDir "evidence") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $caseDir "timeline") | Out-Null
$ts = Get-Date -Format o
$assetLine = if ($samplePath) { "- $samplePath" } else { "" }

$nl = "`n"
$scope = @(
  "# Case Scope",
  "",
  "## meta",
  "- case_id: $CaseName",
  "- created: $ts",
  "- primary_skill: TBD-after-route",
  "- project_root: $ProjectRoot",
  "- skill_root: $Root",
  "- hint: $Hint",
  "",
  "## auth",
  "- status: $authStatus",
  "- basis: $basis",
  "- evidence_of_auth: $evidence",
  "- MUST NOT proceed if status != granted",
  "",
  "## in_scope",
  "- assets:"
) -join $nl
if ($assetLine) { $scope += $nl + $assetLine }
$scope += $nl + (@(
  "- surfaces: []",
  "- activities: [reverse, report]",
  "",
  "## out_of_scope",
  "- assets: []",
  "- activities: [unauthorized_scan, credential_theft, persistence, edr_bypass]",
  "",
  "## network_profile",
  "- mode: $network",
  "- notes: offline = static local only",
  "",
  "## deliverables",
  "- report: true",
  "- timeline: true"
) -join $nl)
# Ensure trailing newline
if (-not $scope.EndsWith($nl)) { $scope += $nl }

Write-Utf8NoBom -Path (Join-Path $caseDir "scope.md") -Content $scope

$ready = ($authStatus -eq "granted")
Write-Output "ROOT=$Root"
Write-Output "CASE_DIR=$caseDir"
Write-Output "auth.status=$authStatus"
Write-Output ("ready_for_act=" + ($(if ($ready) { "true" } else { "false" })))
if (-not $ready) {
  Write-Warning "STOP: auth.status is not granted — docs/routing only until granted or offline-sample preset."
}
