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
    $OutputDirectory = Join-Path $repoRoot 'artifacts\formal-tower-live'
}
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$commitSha = (& git -C $repoRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commitSha)) {
    throw 'Unable to resolve the Formal Tower capture commit SHA.'
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
    @{ Label = 'desktop-1120x720'; Viewport = '1120x720' },
    @{ Label = 'narrow-760x540'; Viewport = '760x540' }
)

& $GodotPath `
    --audio-driver Dummy `
    --path $repoRoot `
    --script res://scripts/tools/capture_cardfront_formal_tower_state_board.gd
if ($LASTEXITCODE -ne 0) {
    throw "Formal Tower state-board capture failed with exit code $LASTEXITCODE"
}

try {
    $env:CARDFRONT_FT1_COMMIT_SHA = $commitSha
    $env:CARDFRONT_FT1_WORKTREE_DIRTY = if ($workingTreeDirty) { 'true' } else { 'false' }
    $env:CARDFRONT_FT1_CHANGED_PATHS = $changedPaths -join '|'
    $env:CARDFRONT_FT1_OUTPUT_DIR = $OutputDirectory
    foreach ($captureConfig in $captureConfigs) {
        $env:CARDFRONT_FT1_CAPTURE_LABEL = $captureConfig.Label
        $env:CARDFRONT_FT1_CAPTURE_VIEWPORT = $captureConfig.Viewport
        & $GodotPath `
            --audio-driver Dummy `
            --path $repoRoot `
            --script res://scripts/tools/capture_cardfront_formal_tower_live.gd
        if ($LASTEXITCODE -ne 0) {
            throw "Formal Tower live capture failed for $($captureConfig.Label) with exit code $LASTEXITCODE"
        }
    }
}
finally {
    Remove-Item Env:CARDFRONT_FT1_COMMIT_SHA -ErrorAction SilentlyContinue
    Remove-Item Env:CARDFRONT_FT1_WORKTREE_DIRTY -ErrorAction SilentlyContinue
    Remove-Item Env:CARDFRONT_FT1_CHANGED_PATHS -ErrorAction SilentlyContinue
    Remove-Item Env:CARDFRONT_FT1_OUTPUT_DIR -ErrorAction SilentlyContinue
    Remove-Item Env:CARDFRONT_FT1_CAPTURE_LABEL -ErrorAction SilentlyContinue
    Remove-Item Env:CARDFRONT_FT1_CAPTURE_VIEWPORT -ErrorAction SilentlyContinue
}

Write-Host "Formal Tower capture matrix complete: $OutputDirectory"
