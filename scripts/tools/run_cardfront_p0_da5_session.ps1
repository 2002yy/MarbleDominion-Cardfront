param(
    [string]$GodotPath = 'D:\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe',
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
$minimumRc = 'f2e427043aa34a422f50d4f52559bd11eabed623'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path

if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw "Godot console executable not found: $GodotPath"
}

$branch = (& git -C $repoRoot branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'main') {
    throw "P0-DA5 must run from branch main; current branch: $branch"
}

$commitSha = (& git -C $repoRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commitSha)) {
    throw 'Unable to resolve the P0-DA5 source commit.'
}

$originMainSha = (& git -C $repoRoot rev-parse refs/remotes/origin/main).Trim()
if ($LASTEXITCODE -ne 0 -or $originMainSha -ne $commitSha) {
    throw "HEAD must exactly match local origin/main. HEAD=$commitSha origin/main=$originMainSha"
}

$remoteMainOutput = @(& git -C $repoRoot ls-remote --exit-code origin refs/heads/main)
if ($LASTEXITCODE -ne 0 -or $remoteMainOutput.Count -eq 0) {
    throw 'Unable to verify the live remote main ref. P0-DA5 fails closed when remote identity is unavailable.'
}
$remoteMainLine = [string]$remoteMainOutput[0]
if ([string]::IsNullOrWhiteSpace($remoteMainLine)) {
    throw 'Live remote main returned an empty identity. P0-DA5 fails closed.'
}
$remoteMainSha = ($remoteMainLine -split '\s+')[0]
if ($remoteMainSha -ne $commitSha) {
    throw "HEAD must exactly match live remote main. HEAD=$commitSha remote=$remoteMainSha"
}

& git -C $repoRoot merge-base --is-ancestor $minimumRc $commitSha
if ($LASTEXITCODE -ne 0) {
    throw "Tested commit must descend from the minimum eligible RC $minimumRc"
}

$statusLines = @(& git -C $repoRoot status --porcelain=v1 --untracked-files=all)
if ($statusLines.Count -gt 0) {
    throw 'P0-DA5 requires a clean worktree. Commit or remove task changes before the session.'
}

$godotVersionOutput = @(& $GodotPath --version)
$godotVersionExitCode = $LASTEXITCODE
$godotVersion = ([string]($godotVersionOutput | Select-Object -First 1)).Trim()
if ($godotVersionExitCode -ne 0 -or $godotVersion -notmatch '^4\.7\.1') {
    throw "P0-DA5 requires Godot 4.7.1; detected: $godotVersion"
}

$startedAt = Get-Date
$timestamp = $startedAt.ToString('yyyyMMdd-HHmmss')
$shortSha = $commitSha.Substring(0, 7)
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repoRoot "artifacts\p0-da5-human\$timestamp-$shortSha"
}
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
$normalizedRepoRoot = [System.IO.Path]::GetFullPath($repoRoot).TrimEnd('\', '/')
$requiredPrefix = $normalizedRepoRoot + [System.IO.Path]::DirectorySeparatorChar
if (-not $OutputDirectory.StartsWith($requiredPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'P0-DA5 evidence directory must remain inside the repository workspace.'
}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$manifestPath = Join-Path $OutputDirectory 'session_manifest.json'
$notesPath = Join-Path $OutputDirectory 'session_notes.md'
$manifest = [ordered]@{
    gate = 'P0-DA5'
    source_commit = $commitSha
    minimum_eligible_rc = $minimumRc
    branch = $branch
    origin_main_commit = $originMainSha
    origin_main_matches_head = $true
    remote_main_commit = $remoteMainSha
    remote_main_matches_head = $true
    worktree_clean = $true
    godot_path = $GodotPath
    godot_version = $godotVersion
    session_started_at = $startedAt.ToString('o')
    protocol = 'docs/cardfront_refactor_checkpoints/P0-DA5_current_main_human_north_star.md'
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding utf8

$notes = @(
    '# P0-DA5 Independent Human Session Notes',
    '',
    "- Tester:",
    '- Tester independent from implementation: YES / NO',
    "- Date/time: $($startedAt.ToString('o'))",
    "- Source commit: $commitSha",
    "- Branch: $branch",
    "- HEAD matches local origin/main: YES ($originMainSha)",
    "- HEAD matches live remote main: YES ($remoteMainSha)",
    '- Clean worktree: YES',
    "- Godot version: $godotVersion",
    '- Recording or timestamped notes path:',
    '- Phase A unbriefed: YES / NO',
    '- Strategic hints before phase A answers: YES / NO',
    '',
    '## Phase A unprompted answers',
    '',
    '1. Two routes:',
    '2. Deployment difference:',
    '3. Support suppression/capture:',
    '4. Options after pushback:',
    '5. Combat versus control roles:',
    '6. Decisive moment and recovery chance:',
    '',
    '## Phase B real-runtime scenarios',
    '',
    '- [ ] 1. Normal advance',
    '- [ ] 2. Main route lost; alternate branch remains useful',
    '- [ ] 3. Core-only counterattack after frontline Supports are lost',
    '- [ ] 4. Strong plus low-cost control unit converts pressure into a claim',
    '- [ ] 5. Repeated Draft -> Battlefield Preview -> return preserves pause and choices',
    '- [ ] 6. CapturedOffline is visible',
    '- [ ] 7. Owned-but-offline deployment denial is observed and explained',
    '',
    '## Findings',
    '',
    '- Observed failures:',
    '- Fair-chance finding:',
    '- Decision: GO / NO-GO',
    '- Reviewer:',
    '- Review date/time:'
)
$notes | Set-Content -LiteralPath $notesPath -Encoding utf8

Write-Host "P0-DA5 evidence prepared: $OutputDirectory"
Write-Host 'Keep the tester unbriefed about route and Support semantics until phase A answers are recorded.'
Write-Host "Host notes: $notesPath"

& $GodotPath --path $repoRoot
$gameExitCode = $LASTEXITCODE

$exitRecord = [ordered]@{
    gate = 'P0-DA5'
    source_commit = $commitSha
    game_exit_code = $gameExitCode
    session_process_ended_at = (Get-Date).ToString('o')
    notes_path = $notesPath
}
$exitRecord | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'session_exit.json') -Encoding utf8

if ($gameExitCode -ne 0) {
    throw "Cardfront session exited with code $gameExitCode"
}

Write-Host 'Game process closed. Complete the notes and preserve the independent reviewer decision.'
