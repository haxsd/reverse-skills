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

function Get-PrimaryFromHint([string]$RulesPath, [string]$HintText) {
  return (Get-RouteFromHint $RulesPath $HintText)[0]
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
$primary = Get-PrimaryFromHint (Join-Path $Root 'skills/scripts/route-rules.tsv') $Hint
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
  "- primary_skill: $primaryOut",
  "- project_root: $ProjectRoot",
  "- skill_root: $Root",
  "- hint: $Hint",
  "",
  "## auth",
  "- status: $authStatus",
  "- basis: $basis",
  "- evidence_of_auth: $evidence",
  "- MUST NOT proceed if status != granted",
  "- 检查≠运行/抓包/附加/碰设备账号：获准检查样本不等于获准运行、抓网络、附加进程或触碰设备/账号；这些动作须单独写进 in_scope.activities（离开本地文件还需非 offline 的 network_profile）",
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
  "- timeline: true",
  "- questions: true"
) -join $nl)
# Ensure trailing newline
if (-not $scope.EndsWith($nl)) { $scope += $nl }

Write-Utf8NoBom -Path (Join-Path $caseDir "scope.md") -Content $scope

# questions.md template (kept if it already exists — it holds case work)
$questionsPath = Join-Path $caseDir "questions.md"
if (-not (Test-Path -LiteralPath $questionsPath -PathType Leaf)) {
  $questions = (@(
    '# Questions',
    '',
    '<!--',
    '大任务（覆盖多个功能或子系统）先在这里列问题，以及每条需要什么证据；见 skills/core/evidence-labels.md。',
    '每条一个 "## Q<n>: <问题>" 小节，新条目默认 status: unanswered。',
    '收尾时每条必须改成且只能是其一：answered（已回答） / partially-answered（部分回答） / unresolved（未解决）。',
    '有界否定写成「在范围 X 内未找到」，不能写成「不存在」。review_case.py 会核对状态（--strict 时缺状态或仍为 unanswered 判失败）。',
    '',
    '示例：',
    '## Q1: <问题>',
    '- evidence_needed: <需要什么证据>',
    '- status: unanswered',
    '- answer: <结论 + 证据标签，或有界否定>',
    '-->'
  ) -join $nl) + $nl
  Write-Utf8NoBom -Path $questionsPath -Content $questions
}

$ready = ($authStatus -eq "granted")
Write-Output "ROOT=$Root"
Write-Output "PRIMARY=$primaryOut"
Write-Output "CASE_DIR=$caseDir"
Write-Output "auth.status=$authStatus"
Write-Output ("ready_for_act=" + ($(if ($ready) { "true" } else { "false" })))
if (-not $ready) {
  Write-Warning "STOP: auth.status is not granted — docs/routing only until granted or offline-sample preset."
}
