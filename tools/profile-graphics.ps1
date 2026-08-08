param(
    [string]$GodotPath = "",
    [string]$OutputPath = "",
    [string]$BaselinePath = "",
    [double]$MaxRegressionPercent = 50.0,
    [double]$AbsoluteAllowanceMs = 0.75
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "godot_helpers.ps1")

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$godotExecutable = Resolve-GodotExecutable -RequestedPath $GodotPath
if (-not $OutputPath) {
    $OutputPath = Join-Path $repoRoot "build\performance\graphics_latest.json"
}
if (-not $BaselinePath) {
    $BaselinePath = Join-Path $repoRoot "performance\baselines\windows_graphics_godot_4_7.json"
}
$resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
$resolvedBaseline = [IO.Path]::GetFullPath($BaselinePath)
$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$profileAppData = [IO.Path]::GetFullPath((Join-Path $temporaryBase ("wow-battleheart-graphics-profile-" + [guid]::NewGuid().ToString("N"))))
if (-not $profileAppData.StartsWith($temporaryBase, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to create graphics-profile data outside the temporary directory."
}
New-Item -ItemType Directory -Path $profileAppData | Out-Null

$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = $godotExecutable
$startInfo.Arguments = "--path `"$repoRoot`" --script res://tools/profile_graphics.gd -- --output=`"$resolvedOutput`""
$startInfo.WorkingDirectory = $repoRoot
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $false
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.EnvironmentVariables["APPDATA"] = $profileAppData
$startInfo.EnvironmentVariables["WOW_BATTLEHEART_TEST_MODE"] = "1"
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $startInfo

try {
    if (-not $process.Start()) { throw "Unable to start the graphical Godot profile." }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(60000)) {
        $process.Kill()
        throw "The graphical profile exceeded the 60-second safety timeout."
    }
    $process.WaitForExit()
    $output = $stdoutTask.Result + $stderrTask.Result
    if ($output.Trim()) { Write-Host $output.TrimEnd() }
    if ($process.ExitCode -ne 0) { throw "The graphical profile exited with code $($process.ExitCode)." }
    if ($output -match "(?im)SCRIPT ERROR|Parse Error|Parser Error") { throw "The graphical profile reported a script or parser error." }
    if (-not (Test-Path -LiteralPath $resolvedOutput -PathType Leaf)) { throw "The graphical profile did not create $resolvedOutput." }

    $report = Get-Content -LiteralPath $resolvedOutput -Raw | ConvertFrom-Json
    if (-not $report.video_adapter_name) { throw "The profile did not report a graphics adapter; it may have run headlessly." }
    Write-Host "== Graphics adapter =="
    Write-Host ("{0} | {1} | {2} | {3}" -f $report.video_adapter_name, $report.rendering_method, $report.rendering_driver, $report.video_adapter_api_version)
    Write-Host "== Visible rendering profile =="
    $report.scenarios | ForEach-Object {
        [pscustomobject]@{
            Scenario = $_.scenario
            MeanFPS = [math]::Round($_.estimated_fps_mean, 1)
            FrameP95Ms = [math]::Round($_.frame_ms.p95, 3)
            RenderSetupP95Ms = [math]::Round($_.render_setup_cpu_ms.p95, 3)
            DrawCallsMean = [math]::Round($_.draw_calls.mean, 1)
            VideoMemoryMB = [math]::Round($_.video_memory_bytes / 1MB, 2)
        }
    } | Format-Table -AutoSize
    if (Test-Path -LiteralPath $resolvedBaseline -PathType Leaf) {
        $baseline = Get-Content -LiteralPath $resolvedBaseline -Raw | ConvertFrom-Json
        $comparable = $report.video_adapter_name -eq $baseline.video_adapter_name -and
            $report.rendering_method -eq $baseline.rendering_method -and
            $report.rendering_driver -eq $baseline.rendering_driver -and
            $report.window_size.width -eq $baseline.window_size.width -and
            $report.window_size.height -eq $baseline.window_size.height
        if ($comparable) {
            $regressions = @()
            foreach ($currentScenario in $report.scenarios) {
                $baselineScenario = @($baseline.scenarios | Where-Object { $_.scenario -eq $currentScenario.scenario }) | Select-Object -First 1
                if (-not $baselineScenario) { continue }
                $baselineValue = [double]$baselineScenario.frame_ms.p95
                $currentValue = [double]$currentScenario.frame_ms.p95
                $limit = [math]::Max($baselineValue * (1.0 + $MaxRegressionPercent / 100.0), $baselineValue + $AbsoluteAllowanceMs)
                if ($currentValue -gt $limit) {
                    $regressions += "$($currentScenario.scenario) frame p95 is $([math]::Round($currentValue, 3)) ms; baseline $([math]::Round($baselineValue, 3)) ms; limit $([math]::Round($limit, 3)) ms"
                }
            }
            if ($regressions.Count -gt 0) { throw "Graphics baseline regression:`n - " + ($regressions -join "`n - ") }
            Write-Host "GRAPHICS_BASELINE_PASSED"
        }
        else {
            Write-Warning "Skipping graphics baseline comparison because the adapter, renderer, or window size differs from the capture environment."
        }
    }
    else {
        Write-Warning "No graphics baseline found at $resolvedBaseline."
    }
    Write-Host "GRAPHICS_PROFILE_PASSED"
}
finally {
    $process.Dispose()
    if ($profileAppData.StartsWith($temporaryBase, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path $profileAppData -Leaf).StartsWith("wow-battleheart-graphics-profile-")) {
        Remove-Item -LiteralPath $profileAppData -Recurse -Force -ErrorAction SilentlyContinue
    }
}
