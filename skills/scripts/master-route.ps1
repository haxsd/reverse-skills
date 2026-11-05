# Thin master-route for haxsd/reverse-skills v0.1.0
param(
  [Parameter(Mandatory = $false)][string]$Hint = ""
)
if (-not $Hint) { Write-Error "Usage: master-route.ps1 -Hint <task>"; exit 2 }
$h = $Hint.ToLowerInvariant()
$primary = "skills/triage/"
$reason = "default triage for unknown/general sample"
if ($h -match 'apk|xapk|aar|android|jadx|smali|manifest|retrofit|okhttp|安卓|反编译apk') {
  $primary = "skills/android-apk/"
  $reason = "Android/APK keywords in hint"
}
Write-Output "PRIMARY=$primary"
Write-Output "REASON=$reason"
Write-Output "HINT=$Hint"
Write-Output "NEXT=Read ${primary}SKILL.md after case-init scope is ready"
