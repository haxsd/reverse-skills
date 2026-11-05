# Wrapper: registry tool check (shared implementation: check_tools.py)
[CmdletBinding()]
param(
  [string]$Skill = ""
)

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }

$py = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command python -ErrorAction SilentlyContinue }
if (-not $py) {
  Write-Error "python3/python required (not found in PATH)"
  exit 2
}

$script = Join-Path $here 'check_tools.py'
if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
  Write-Error "missing shared checker: $script"
  exit 2
}

$argv = @()
if ($Skill) { $argv += @('--skill', $Skill) }

& $py.Source $script @argv
exit $LASTEXITCODE
