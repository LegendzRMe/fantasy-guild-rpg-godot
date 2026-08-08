param(
    [int]$LargeAssetMegabytes = 1,
    [int]$LargeScriptLines = 500,
    [int]$LongLineColumns = 180
)

$ErrorActionPreference = "Stop"
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$scriptFiles = Get-ChildItem -LiteralPath (Join-Path $repoRoot "scripts"), (Join-Path $repoRoot "tests") -Recurse -File -Filter "*.gd"
$scriptMetrics = foreach ($file in $scriptFiles) {
    $lines = Get-Content -LiteralPath $file.FullName
    [pscustomobject]@{
        File = $file.FullName.Substring($repoRoot.Length).TrimStart('\')
        Lines = $lines.Count
        LongLines = @($lines | Where-Object { $_.Length -gt $LongLineColumns }).Count
    }
}
$methodMetrics = foreach ($file in $scriptFiles) {
    $lines = @(Get-Content -LiteralPath $file.FullName)
    $starts = @()
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^func\s+([^(:]+)') {
            $starts += [pscustomobject]@{ Index = $index; Name = $Matches[1] }
        }
    }
    for ($methodIndex = 0; $methodIndex -lt $starts.Count; $methodIndex++) {
        $nextIndex = if ($methodIndex + 1 -lt $starts.Count) { $starts[$methodIndex + 1].Index } else { $lines.Count }
        [pscustomobject]@{
            File = $file.FullName.Substring($repoRoot.Length).TrimStart('\')
            Method = $starts[$methodIndex].Name
            StartLine = $starts[$methodIndex].Index + 1
            Lines = $nextIndex - $starts[$methodIndex].Index
        }
    }
}

Write-Host "== GDScript inventory =="
Write-Host ("{0} files, {1} total lines" -f $scriptMetrics.Count, (($scriptMetrics | Measure-Object Lines -Sum).Sum))
$scriptMetrics | Sort-Object Lines -Descending | Select-Object -First 15 | Format-Table -AutoSize

Write-Host "== Scripts over $LargeScriptLines lines =="
$largeScripts = @($scriptMetrics | Where-Object { $_.Lines -gt $LargeScriptLines } | Sort-Object Lines -Descending)
if ($largeScripts) { $largeScripts | Format-Table -AutoSize } else { Write-Host "None." }

Write-Host "== Lines over $LongLineColumns columns =="
$longLineFiles = @($scriptMetrics | Where-Object { $_.LongLines -gt 0 } | Sort-Object LongLines -Descending)
if ($longLineFiles) {
    Write-Host ("{0} files contain long lines; showing the top 20." -f $longLineFiles.Count)
    $longLineFiles | Select-Object -First 20 | Format-Table -AutoSize
} else { Write-Host "None." }

Write-Host "== Largest methods =="
$methodMetrics | Sort-Object Lines -Descending | Select-Object -First 20 | Format-Table -AutoSize

Write-Host "== Assets at least $LargeAssetMegabytes MB =="
$minimumBytes = $LargeAssetMegabytes * 1MB
$largeAssets = Get-ChildItem -LiteralPath (Join-Path $repoRoot "assets") -Recurse -File |
    Where-Object { $_.Extension -ne ".import" -and $_.Length -ge $minimumBytes } |
    Sort-Object Length -Descending |
    ForEach-Object {
        [pscustomobject]@{
            File = $_.FullName.Substring($repoRoot.Length).TrimStart('\')
            Megabytes = [math]::Round($_.Length / 1MB, 2)
        }
    }
if ($largeAssets) { $largeAssets | Format-Table -AutoSize } else { Write-Host "None." }

Write-Host "== Largest imported textures =="
$importedTextures = foreach ($importFile in Get-ChildItem -LiteralPath (Join-Path $repoRoot "assets") -Recurse -File -Filter "*.png.import") {
    $importText = Get-Content -LiteralPath $importFile.FullName -Raw
    $sourceMatch = [regex]::Match($importText, 'source_file="res://([^"]+)"')
    $cacheMatch = [regex]::Match($importText, 'path="res://([^"]+\.ctex)"')
    if (-not $sourceMatch.Success -or -not $cacheMatch.Success) { continue }
    $cachePath = Join-Path $repoRoot $cacheMatch.Groups[1].Value.Replace('/', '\')
    if (-not (Test-Path -LiteralPath $cachePath -PathType Leaf)) { continue }
    [pscustomobject]@{
        File = $sourceMatch.Groups[1].Value.Replace('/', '\')
        ImportedMegabytes = [math]::Round((Get-Item -LiteralPath $cachePath).Length / 1MB, 3)
    }
}
$importedTextures | Sort-Object ImportedMegabytes -Descending | Select-Object -First 15 | Format-Table -AutoSize

Write-Host "== Runtime coupling indicators =="
$patterns = @("get_tree().root", "find_child(", "save_game(")
$productionFiles = @($scriptFiles | Where-Object { $_.FullName.StartsWith((Join-Path $repoRoot "scripts"), [StringComparison]::OrdinalIgnoreCase) })
$testFiles = @($scriptFiles | Where-Object { $_.FullName.StartsWith((Join-Path $repoRoot "tests"), [StringComparison]::OrdinalIgnoreCase) })
$couplingRows = foreach ($pattern in $patterns) {
    $productionMatches = @(Select-String -LiteralPath $productionFiles.FullName -SimpleMatch -Pattern $pattern)
    $testMatches = @(Select-String -LiteralPath $testFiles.FullName -SimpleMatch -Pattern $pattern)
    [pscustomobject]@{
        Pattern = $pattern
        Production = $productionMatches.Count
        Tests = $testMatches.Count
    }
}
$couplingRows | Format-Table -AutoSize

Write-Host "AUDIT_COMPLETE"
