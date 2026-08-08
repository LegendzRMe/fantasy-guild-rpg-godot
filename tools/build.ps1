param(
    [string]$GodotPath = "",
    [string]$OutputDirectory = "",
    [string]$BuildId = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "godot_helpers.ps1")

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$godotExecutable = Resolve-GodotExecutable -RequestedPath $GodotPath
$consoleCandidate = Join-Path (Split-Path $godotExecutable -Parent) (([IO.Path]::GetFileNameWithoutExtension($godotExecutable)) + "_console.exe")
$godotCommand = if (Test-Path -LiteralPath $consoleCandidate -PathType Leaf) { $consoleCandidate } else { $godotExecutable }
$engineVersion = (Get-Item -LiteralPath $godotExecutable).VersionInfo.ProductVersion
$templateVersion = $engineVersion -replace '\.official.*$', ''
$releaseTemplate = Join-Path $env:APPDATA "Godot\export_templates\$templateVersion\windows_release_x86_64.exe"
if (-not (Test-Path -LiteralPath $releaseTemplate -PathType Leaf)) {
    throw "Godot $templateVersion Windows export templates are not installed. Run .\tools\install_export_templates.ps1 first."
}
if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $repoRoot "build\windows"
}
$resolvedOutput = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $resolvedOutput -Force | Out-Null

$outputExecutable = Join-Path $resolvedOutput "FantasyGuildBattleheart.exe"
Write-Host "Validating before export..."
& (Join-Path $PSScriptRoot "validate.ps1") -GodotPath $godotExecutable
if ($LASTEXITCODE -ne 0) {
    throw "Validation failed; export was not attempted."
}

Write-Host "Exporting Windows Desktop release to $outputExecutable"
& $godotCommand --headless --path $repoRoot --export-release "Windows Desktop" $outputExecutable
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $outputExecutable -PathType Leaf)) {
    throw "Godot export failed. Confirm that the matching Godot export templates are installed."
}

Write-Host "Smoke-testing exported executable..."
$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$smokeAppData = [IO.Path]::GetFullPath((Join-Path $temporaryBase ("codex-wow-battleheart-build-" + [guid]::NewGuid().ToString("N"))))
if (-not $smokeAppData.StartsWith($temporaryBase, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to create build smoke-test data outside the temporary directory."
}
New-Item -ItemType Directory -Path $smokeAppData | Out-Null
$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = $outputExecutable
$startInfo.Arguments = "--headless --quit-after 3"
$startInfo.WorkingDirectory = $resolvedOutput
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.EnvironmentVariables["APPDATA"] = $smokeAppData
$startInfo.EnvironmentVariables["WOW_BATTLEHEART_TEST_MODE"] = "1"
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $startInfo
try {
    if (-not $process.Start()) { throw "Unable to start the exported executable." }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(30000)) {
        $process.Kill()
        throw "The exported executable exceeded the 30-second smoke-test timeout."
    }
    $process.WaitForExit()
    $smokeOutput = $stdoutTask.Result + $stderrTask.Result
    if ($smokeOutput.Trim()) { Write-Host $smokeOutput.TrimEnd() }
    if ($process.ExitCode -ne 0) { throw "The exported executable exited with code $($process.ExitCode)." }
    if ($smokeOutput -match "(?im)SCRIPT ERROR|Parse Error|Parser Error") {
        throw "The exported executable reported a script or parser error."
    }
}
finally {
    $process.Dispose()
    Remove-Item -LiteralPath $smokeAppData -Recurse -Force -ErrorAction SilentlyContinue
}

if (-not $BuildId) {
    $commit = (& git -C $repoRoot rev-parse --short HEAD 2>$null)
    $BuildId = if ($LASTEXITCODE -eq 0 -and $commit) { $commit.Trim() } else { "local" }
    $worktreeChanges = (& git -C $repoRoot status --porcelain 2>$null)
    if ($worktreeChanges) { $BuildId += "-dirty" }
}
$projectText = Get-Content -LiteralPath (Join-Path $repoRoot "project.godot") -Raw
$versionMatch = [regex]::Match($projectText, '(?m)^config/version="([^"]+)"$')
$version = if ($versionMatch.Success) { $versionMatch.Groups[1].Value } else { "development" }
$metadata = [ordered]@{
    product = "Fantasy Guild Battleheart RPG"
    version = $version
    build_id = $BuildId
    godot = $engineVersion
    created_utc = [DateTime]::UtcNow.ToString("o")
    executable = [IO.Path]::GetFileName($outputExecutable)
}
$metadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $resolvedOutput "build-info.json") -Encoding UTF8
Write-Host "BUILD_SUCCEEDED"
