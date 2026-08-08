param(
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "godot_helpers.ps1")

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$godotExecutable = Resolve-GodotExecutable -RequestedPath $GodotPath

Write-Host "Launching Fantasy Guild Battleheart RPG with $godotExecutable"
& $godotExecutable --path $repoRoot
if ($LASTEXITCODE -ne 0) {
    throw "Godot exited with code $LASTEXITCODE."
}
