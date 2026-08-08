param(
    [string]$GodotVersion = "4.7-stable"
)

$ErrorActionPreference = "Stop"
$templateVersion = $GodotVersion.Replace("-", ".")
$templateRoot = Join-Path $env:APPDATA "Godot\export_templates"
$destination = Join-Path $templateRoot $templateVersion
$requiredTemplate = Join-Path $destination "windows_release_x86_64.exe"
if (Test-Path -LiteralPath $requiredTemplate -PathType Leaf) {
    Write-Host "Godot $templateVersion export templates are already installed."
    exit 0
}

$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$temporaryRoot = [IO.Path]::GetFullPath((Join-Path $temporaryBase ("wow-battleheart-templates-" + [guid]::NewGuid().ToString("N"))))
$archive = Join-Path $temporaryRoot "export-templates.zip"
$expanded = Join-Path $temporaryRoot "expanded"
$url = "https://github.com/godotengine/godot-builds/releases/download/$GodotVersion/Godot_v$GodotVersion`_export_templates.tpz"

New-Item -ItemType Directory -Path $temporaryRoot, $expanded -Force | Out-Null
try {
    Write-Host "Downloading official Godot $GodotVersion export templates..."
    Invoke-WebRequest -Uri $url -OutFile $archive
    Expand-Archive -LiteralPath $archive -DestinationPath $expanded
    $source = Join-Path $expanded "templates"
    if (-not (Test-Path -LiteralPath (Join-Path $source "windows_release_x86_64.exe") -PathType Leaf)) {
        throw "The downloaded archive did not contain the expected Windows release template."
    }
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    Copy-Item -Path (Join-Path $source "*") -Destination $destination -Recurse -Force
    if (-not (Test-Path -LiteralPath $requiredTemplate -PathType Leaf)) {
        throw "Template installation did not produce $requiredTemplate."
    }
    Write-Host "EXPORT_TEMPLATES_INSTALLED"
}
finally {
    if ($temporaryRoot.StartsWith($temporaryBase, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path $temporaryRoot -Leaf).StartsWith("wow-battleheart-templates-")) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
