param(
    [string]$GodotPath = 'D:\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe',
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw "Godot console executable not found: $GodotPath"
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repoRoot 'artifacts\projectile-grammar-pg1'
}
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$commitSha = (& git -C $repoRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commitSha)) {
    throw 'Unable to resolve the capture commit SHA.'
}
$statusLines = @(& git -C $repoRoot status --porcelain=v1 --untracked-files=all)
$workingTreeDirty = $statusLines.Count -gt 0
$changedPaths = @(
    $statusLines |
        ForEach-Object {
            if ($_.Length -gt 3) { $_.Substring(3) } else { $_ }
        }
)

$captureConfigs = @(
    @{ Label = 'desktop-1120x720-scale-100'; Viewport = '1120x720'; Scale = '1.00' },
    @{ Label = 'desktop-1120x720-scale-112'; Viewport = '1120x720'; Scale = '1.12' },
    @{ Label = 'narrow-760x540-scale-112'; Viewport = '760x540'; Scale = '1.12' }
)

try {
    $env:CARDFRONT_PG1_COMMIT_SHA = $commitSha
    $env:CARDFRONT_PG1_WORKTREE_DIRTY = if ($workingTreeDirty) { 'true' } else { 'false' }
    $env:CARDFRONT_PG1_CHANGED_PATHS = $changedPaths -join '|'
    $env:CARDFRONT_PG1_OUTPUT_DIR = $OutputDirectory
    foreach ($captureConfig in $captureConfigs) {
        $env:CARDFRONT_PG1_CAPTURE_LABEL = $captureConfig.Label
        $env:CARDFRONT_PG1_CAPTURE_VIEWPORT = $captureConfig.Viewport
        $env:CARDFRONT_PG1_PRESENTATION_SCALE = $captureConfig.Scale
        & $GodotPath `
            --audio-driver Dummy `
            --path $repoRoot `
            --script res://scripts/tools/capture_cardfront_projectile_grammar.gd
        if ($LASTEXITCODE -ne 0) {
            throw "PG1 capture failed for $($captureConfig.Label) with exit code $LASTEXITCODE"
        }
    }
}
finally {
    Remove-Item Env:CARDFRONT_PG1_COMMIT_SHA -ErrorAction SilentlyContinue
    Remove-Item Env:CARDFRONT_PG1_WORKTREE_DIRTY -ErrorAction SilentlyContinue
    Remove-Item Env:CARDFRONT_PG1_CHANGED_PATHS -ErrorAction SilentlyContinue
    Remove-Item Env:CARDFRONT_PG1_OUTPUT_DIR -ErrorAction SilentlyContinue
    Remove-Item Env:CARDFRONT_PG1_CAPTURE_LABEL -ErrorAction SilentlyContinue
    Remove-Item Env:CARDFRONT_PG1_CAPTURE_VIEWPORT -ErrorAction SilentlyContinue
    Remove-Item Env:CARDFRONT_PG1_PRESENTATION_SCALE -ErrorAction SilentlyContinue
}

Write-Host "PG1 capture matrix complete: $OutputDirectory"
