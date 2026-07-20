param(
    [string]$GodotPath = "",
    [int]$Iterations = 100,
    [int]$Level = 1,
    [int]$Seed = 1337,
    [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
if (-not $OutputDirectory) {
    $projectName = Split-Path $repoRoot -Leaf
    $OutputDirectory = Join-Path (Split-Path $repoRoot -Parent) ($projectName + " Balance Reports")
}

if (-not $GodotPath) {
    foreach ($commandName in @("godot4", "godot")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) { $GodotPath = $command.Source; break }
    }
}
if (-not $GodotPath) {
    $wingetRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path -LiteralPath $wingetRoot) {
        $GodotPath = Get-ChildItem -LiteralPath $wingetRoot -Recurse -Filter "Godot_v*-stable_win64.exe" -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -ExpandProperty FullName -First 1
    }
}
if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw "Godot was not found. Pass its path with -GodotPath."
}

$arguments = @(
    "--headless", "--path", $repoRoot,
    "--script", "res://tools/run_balance_simulation.gd", "--",
    "--iterations", $Iterations,
    "--level", $Level,
    "--seed", $Seed,
    "--output-dir", $OutputDirectory
)
$output = & $GodotPath @arguments 2>&1 | Out-String
if ($output.Trim()) { Write-Host $output.TrimEnd() }
if ($LASTEXITCODE -ne 0) {
    throw "Balance simulation failed with exit code $LASTEXITCODE."
}
