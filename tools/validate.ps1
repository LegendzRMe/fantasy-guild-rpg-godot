param(
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
. (Join-Path $PSScriptRoot "godot_helpers.ps1")

function Invoke-GodotStep {
    param(
        [string]$Name,
        [string[]]$Arguments
    )

    Write-Host "== $Name =="
    $escapedArguments = $Arguments | ForEach-Object {
        if ($_ -match '[\s"]') { '"' + $_.Replace('"', '\"') + '"' } else { $_ }
    }
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $script:godotExecutable
    $startInfo.Arguments = $escapedArguments -join ' '
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) { throw "Unable to start $Name." }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(120000)) {
            $process.Kill()
            throw "$Name exceeded the 120-second safety timeout; its Godot process was stopped."
        }
        $process.WaitForExit()
        $exitCode = $process.ExitCode
        $output = $stdoutTask.Result + $stderrTask.Result
        if ($output.Trim()) {
            Write-Host $output.TrimEnd()
        }
        if ($exitCode -ne 0) {
            throw "$Name failed with exit code $exitCode."
        }
        if ($output -match "(?im)SCRIPT ERROR|Parse Error|Parser Error") {
            throw "$Name reported a script or parser error."
        }
    }
    finally {
        $process.Dispose()
    }
}

$godotExecutable = Resolve-GodotExecutable -RequestedPath $GodotPath
$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$testAppData = [IO.Path]::GetFullPath((Join-Path $temporaryBase ("codex-wow-battleheart-validation-" + [guid]::NewGuid().ToString("N"))))
$oldAppData = $env:APPDATA
$oldTestMode = $env:WOW_BATTLEHEART_TEST_MODE

New-Item -ItemType Directory -Path $testAppData | Out-Null

try {
    $env:APPDATA = $testAppData
    $env:WOW_BATTLEHEART_TEST_MODE = "1"

    # Prime the inheritance graph before the editor's parallel first scan. Godot
    # 4.7 can otherwise report a transient unresolved parent when a newly added
    # intermediate script is discovered after one of its descendants.
    Invoke-GodotStep "Godot dependency priming" @("--headless", "--path", $repoRoot, "--script", "res://tools/check_load.gd")
    Invoke-GodotStep "Godot editor parsing" @("--headless", "--editor", "--path", $repoRoot, "--quit")
    Invoke-GodotStep "Imported texture quality" @("--headless", "--path", $repoRoot, "--script", "res://tools/check_texture_quality.gd")
    Invoke-GodotStep "Godot automated tests" @("--headless", "--path", $repoRoot, "--script", "res://tests/run_tests.gd")
    Invoke-GodotStep "Godot startup smoke test" @("--headless", "--path", $repoRoot, "--quit-after", "3")

    $exportPack = Join-Path $testAppData "export-smoke.pck"
    $isolatedPackRoot = Join-Path $testAppData "pack-runtime"
    New-Item -ItemType Directory -Path $isolatedPackRoot | Out-Null
    Invoke-GodotStep "Godot export preset smoke test" @("--headless", "--path", $repoRoot, "--export-pack", "Windows Desktop", $exportPack)
    if (-not (Test-Path -LiteralPath $exportPack -PathType Leaf)) {
        throw "The Windows Desktop export preset did not create its smoke-test pack."
    }
    Invoke-GodotStep "Exported pack startup smoke test" @("--headless", "--path", $isolatedPackRoot, "--main-pack", $exportPack, "--quit-after", "3")

    $runtimeLog = Join-Path $testAppData "Godot\app_userdata\Fantasy Guild Battleheart RPG\logs\godot.log"
    if (-not (Test-Path -LiteralPath $runtimeLog -PathType Leaf)) {
        throw "Godot runtime log was not created."
    }
    $runtimeErrors = Select-String -LiteralPath $runtimeLog -Pattern "SCRIPT ERROR", "Parse Error", "Parser Error", "ERROR:" -SimpleMatch
    if ($runtimeErrors) {
        throw "Godot runtime log contains errors:`n$($runtimeErrors -join [Environment]::NewLine)"
    }
    Write-Host "== Runtime log =="
    Write-Host "No script, parser, or runtime errors found."

    Write-Host "== UTF-8 source hygiene =="
    $sourceRoots = @(
        (Join-Path $repoRoot "scripts"),
        (Join-Path $repoRoot "tests"),
        (Join-Path $repoRoot "docs"),
        (Join-Path $repoRoot "README.md")
    )
    $sourceFiles = Get-ChildItem -LiteralPath $sourceRoots -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in @(".gd", ".md") }
    # Match the usual leading characters of double-encoded UTF-8 without
    # embedding non-ASCII literals in this Windows PowerShell script.
    $encodingArtifacts = Select-String -LiteralPath $sourceFiles.FullName -Pattern '\u00C3|\u00E2'
    if ($encodingArtifacts) {
        throw "Double-encoded UTF-8 text found:`n$($encodingArtifacts -join [Environment]::NewLine)"
    }
    Write-Host "No double-encoded UTF-8 text found."

    Write-Host "== Git whitespace check =="
    & git -C $repoRoot diff --check
    if ($LASTEXITCODE -ne 0) {
        throw "git diff --check failed."
    }
    Write-Host "git diff --check passed."
    Write-Host "VALIDATION_PASSED"
}
finally {
    $env:APPDATA = $oldAppData
    if ($null -eq $oldTestMode) {
        Remove-Item Env:WOW_BATTLEHEART_TEST_MODE -ErrorAction SilentlyContinue
    }
    else {
        $env:WOW_BATTLEHEART_TEST_MODE = $oldTestMode
    }

    $resolvedTestAppData = [IO.Path]::GetFullPath($testAppData)
    if ($resolvedTestAppData.StartsWith($temporaryBase, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path $resolvedTestAppData -Leaf).StartsWith("codex-wow-battleheart-validation-")) {
        Remove-Item -LiteralPath $resolvedTestAppData -Recurse -Force -ErrorAction SilentlyContinue
    }
}
