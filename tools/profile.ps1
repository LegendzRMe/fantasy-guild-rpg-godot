param(
    [string]$GodotPath = "",
    [string]$OutputPath = "",
    [string]$BaselinePath = "",
    [double]$MaxRegressionPercent = 50.0,
    [double]$AbsoluteAllowanceMs = 0.15
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "godot_helpers.ps1")

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$godotExecutable = Resolve-GodotExecutable -RequestedPath $GodotPath
$consoleCandidate = Join-Path (Split-Path $godotExecutable -Parent) (([IO.Path]::GetFileNameWithoutExtension($godotExecutable)) + "_console.exe")
$godotCommand = if (Test-Path -LiteralPath $consoleCandidate -PathType Leaf) { $consoleCandidate } else { $godotExecutable }
if (-not $OutputPath) {
    $OutputPath = Join-Path $repoRoot "build\performance\latest.json"
}
if (-not $BaselinePath) {
    $BaselinePath = Join-Path $repoRoot "performance\baselines\windows_godot_4_7.json"
}
$resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
$resolvedBaseline = [IO.Path]::GetFullPath($BaselinePath)
$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$profileAppData = [IO.Path]::GetFullPath((Join-Path $temporaryBase ("wow-battleheart-profile-" + [guid]::NewGuid().ToString("N"))))
$oldAppData = $env:APPDATA
New-Item -ItemType Directory -Path $profileAppData -Force | Out-Null

try {
    $env:APPDATA = $profileAppData
    & $godotCommand --headless --path $repoRoot --script "res://tools/profile_runtime.gd" -- "--output=$resolvedOutput"
    if ($LASTEXITCODE -ne 0) { throw "Runtime profiling failed with exit code $LASTEXITCODE." }
    if (-not (Test-Path -LiteralPath $resolvedOutput -PathType Leaf)) { throw "Runtime profiling did not create $resolvedOutput." }
    $report = Get-Content -LiteralPath $resolvedOutput -Raw | ConvertFrom-Json
    Write-Host "== Deterministic runtime profile =="
    $report.scenarios | Select-Object scenario, update_ms_mean, update_ms_median, update_ms_p95, update_ms_p99, update_ms_max, scene_nodes, heroes, enemies | Format-Table -AutoSize
    if (Test-Path -LiteralPath $resolvedBaseline -PathType Leaf) {
        $baseline = Get-Content -LiteralPath $resolvedBaseline -Raw | ConvertFrom-Json
        $comparable = $report.platform -eq $baseline.platform -and
            $report.godot_version -eq $baseline.godot_version -and
            $report.processor_count -eq $baseline.processor_count
        if ($comparable) {
            $regressions = @()
            foreach ($currentScenario in $report.scenarios) {
                $baselineScenario = @($baseline.scenarios | Where-Object { $_.scenario -eq $currentScenario.scenario }) | Select-Object -First 1
                if (-not $baselineScenario) { continue }
                foreach ($metric in @("update_ms_median", "update_ms_p95")) {
                    $baselineValue = [double]$baselineScenario.$metric
                    $currentValue = [double]$currentScenario.$metric
                    $relativeLimit = $baselineValue * (1.0 + $MaxRegressionPercent / 100.0)
                    $limit = [math]::Max($relativeLimit, $baselineValue + $AbsoluteAllowanceMs)
                    if ($currentValue -gt $limit) {
                        $regressions += "$($currentScenario.scenario) $metric is $([math]::Round($currentValue, 3)) ms; baseline $([math]::Round($baselineValue, 3)) ms; limit $([math]::Round($limit, 3)) ms"
                    }
                }
            }
            if ($regressions.Count -gt 0) {
                throw "Performance baseline regression:`n - " + ($regressions -join "`n - ")
            }
            Write-Host "PERFORMANCE_BASELINE_PASSED"
        }
        else {
            Write-Warning "Skipping baseline comparison because platform, Godot version, or processor count differs from the capture environment."
        }
    }
    else {
        Write-Warning "No performance baseline found at $resolvedBaseline."
    }
    Write-Host "PERFORMANCE_PROFILE_PASSED"
}
finally {
    $env:APPDATA = $oldAppData
    if ($profileAppData.StartsWith($temporaryBase, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path $profileAppData -Leaf).StartsWith("wow-battleheart-profile-")) {
        Remove-Item -LiteralPath $profileAppData -Recurse -Force -ErrorAction SilentlyContinue
    }
}
