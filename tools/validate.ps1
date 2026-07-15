param(
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))

function Resolve-GodotExecutable {
    if ($GodotPath) {
        if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
            throw "Godot executable not found: $GodotPath"
        }
        return (Resolve-Path -LiteralPath $GodotPath).Path
    }

    foreach ($commandName in @("godot4", "godot")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    $wingetRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path -LiteralPath $wingetRoot) {
        $candidate = Get-ChildItem -LiteralPath $wingetRoot -Recurse -Filter "Godot_v*-stable_win64.exe" -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($candidate) {
            return $candidate.FullName
        }
    }

    throw "Godot was not found. Pass its path with -GodotPath."
}

function Invoke-GodotStep {
    param(
        [string]$Name,
        [string[]]$Arguments
    )

    Write-Host "== $Name =="
    $output = & $script:godotExecutable @Arguments 2>&1 | Out-String
    if ($output.Trim()) {
        Write-Host $output.TrimEnd()
    }
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE."
    }
    if ($output -match "(?im)SCRIPT ERROR|Parse Error|Parser Error") {
        throw "$Name reported a script or parser error."
    }
}

$godotExecutable = Resolve-GodotExecutable
$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$testAppData = [IO.Path]::GetFullPath((Join-Path $temporaryBase ("codex-wow-battleheart-validation-" + [guid]::NewGuid().ToString("N"))))
$oldAppData = $env:APPDATA
$oldTestMode = $env:WOW_BATTLEHEART_TEST_MODE

New-Item -ItemType Directory -Path $testAppData | Out-Null

try {
    $env:APPDATA = $testAppData
    $env:WOW_BATTLEHEART_TEST_MODE = "1"

    Invoke-GodotStep "Godot editor parsing" @("--headless", "--editor", "--path", $repoRoot, "--quit")
    Invoke-GodotStep "Godot automated tests" @("--headless", "--path", $repoRoot, "--script", "res://tests/run_tests.gd")
    Invoke-GodotStep "Godot startup smoke test" @("--headless", "--path", $repoRoot, "--quit-after", "3")

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
