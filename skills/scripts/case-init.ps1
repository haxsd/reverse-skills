# Thin case-init for haxsd/reverse-skills — auth gate aware
param(
  [string]$Hint,
  [string]$CaseName,
  [string]$Preset = "",
  [string]$Sample = "",
  [string]$ProjectRoot = (Get-Location).Path,
  [switch]$AuthGranted,
  [string]$NetworkProfile = "lab_only",
  [string]$AuthBasis = "unknown",
  [string]$EvidenceOfAuth = ""
)
if (-not $Hint -or -not $CaseName) {
  Write-Error "Usage: case-init.ps1 -Hint TEXT -CaseName NAME [-Preset offline-sample -Sample FILE]"
  exit 2
}
$authStatus = if ($AuthGranted) { "granted" } else { "pending" }
$network = $NetworkProfile
$basis = $AuthBasis
$evidence = $EvidenceOfAuth
$samplePath = ""

switch ($Preset) {
  { $_ -in @("offline-sample","own-sample","local-sample") } {
    if (-not $Sample -or -not (Test-Path -LiteralPath $Sample -PathType Leaf)) {
      Write-Error "offline-sample preset requires an existing -Sample file"
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

$caseDir = Join-Path $ProjectRoot "work\$CaseName"
New-Item -ItemType Directory -Force -Path (Join-Path $caseDir "evidence") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $caseDir "timeline") | Out-Null
$ts = Get-Date -Format o
$assetLine = if ($samplePath) { "- $samplePath" } else { "" }

@"
# Case Scope

## meta
- case_id: $CaseName
- created: $ts
- primary_skill: TBD-after-route
- project_root: $ProjectRoot
- hint: $Hint

## auth
- status: $authStatus
- basis: $basis
- evidence_of_auth: $evidence
- MUST NOT proceed if status != granted

## in_scope
- assets:
$assetLine
- surfaces: []
- activities: [reverse, report]

## out_of_scope
- assets: []
- activities: [unauthorized_scan, credential_theft, persistence, edr_bypass]

## network_profile
- mode: $network
- notes: offline = static local only

## deliverables
- report: true
- timeline: true
"@ | Set-Content -LiteralPath (Join-Path $caseDir "scope.md") -Encoding utf8

$ready = ($authStatus -eq "granted")
Write-Output "CASE_DIR=$caseDir"
Write-Output "auth.status=$authStatus"
Write-Output "ready_for_act=$ready"
if (-not $ready) {
  Write-Warning "STOP: auth.status is not granted — docs/routing only until granted or offline-sample preset."
}
