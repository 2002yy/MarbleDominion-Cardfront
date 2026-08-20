param(
    [Parameter(Mandatory = $true)]
    [string]$RenderDirectory,
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$RenderDirectory = (Resolve-Path -LiteralPath $RenderDirectory).Path
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repoRoot 'artifacts\formal-tower-reference'
}
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

Add-Type -AssemblyName System.Drawing

function New-Canvas([int]$Width, [int]$Height) {
    $bitmap = New-Object System.Drawing.Bitmap($Width, $Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::FromArgb(12, 15, 18))
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    return @($bitmap, $graphics)
}

function Draw-Cell($Graphics, [string]$ImagePath, [string]$Label, [int]$X, [int]$Y, [int]$Width, [int]$Height) {
    $image = [System.Drawing.Image]::FromFile($ImagePath)
    try {
        $Graphics.DrawImage($image, $X, $Y, $Width, $Height)
    }
    finally {
        $image.Dispose()
    }
    $labelFont = New-Object System.Drawing.Font('Segoe UI', 15)
    $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(211, 220, 225))
    try {
        $Graphics.DrawString($Label, $labelFont, $labelBrush, $X + 10, $Y + $Height + 3)
    }
    finally {
        $labelBrush.Dispose()
        $labelFont.Dispose()
    }
}

function Draw-Title($Graphics, [string]$Title) {
    $titleFont = New-Object System.Drawing.Font('Segoe UI', 18)
    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(242, 245, 232))
    try {
        $Graphics.DrawString($Title, $titleFont, $titleBrush, 18, 12)
    }
    finally {
        $titleBrush.Dispose()
        $titleFont.Dispose()
    }
}

$damageCanvas = New-Canvas 1500 392
$damageBitmap = $damageCanvas[0]
$damageGraphics = $damageCanvas[1]
try {
    Draw-Title $damageGraphics 'Formal Interceptor Tower - mutually exclusive HP states'
    $damageCells = @(
        @{ State = 'hp4'; View = 'front'; Label = 'HP4 COMPLETE' },
        @{ State = 'hp3'; View = 'front'; Label = 'HP3 LIGHT' },
        @{ State = 'hp2'; View = 'front'; Label = 'HP2 HEAVY' },
        @{ State = 'hp1'; View = 'front'; Label = 'HP1 CRITICAL' },
        @{ State = 'hp0'; View = 'iso'; Label = 'HP0 5-PIECE SNAPSHOT' }
    )
    for ($index = 0; $index -lt $damageCells.Count; $index++) {
        $cell = $damageCells[$index]
        $path = Join-Path $RenderDirectory "$($cell.State)\$($cell.View).png"
        Draw-Cell $damageGraphics $path $cell.Label ($index * 300) 52 300 300
    }
    $damageBitmap.Save(
        (Join-Path $OutputDirectory 'tower_damage_states.png'),
        [System.Drawing.Imaging.ImageFormat]::Png
    )
}
finally {
    $damageGraphics.Dispose()
    $damageBitmap.Dispose()
}

$viewsCanvas = New-Canvas 1400 826
$viewsBitmap = $viewsCanvas[0]
$viewsGraphics = $viewsCanvas[1]
try {
    Draw-Title $viewsGraphics 'Formal Interceptor Tower - HP4 seven-view reference'
    $views = @(
        @{ View = 'front'; Label = 'FRONT'; X = 0; Y = 52 },
        @{ View = 'back'; Label = 'BACK'; X = 350; Y = 52 },
        @{ View = 'left'; Label = 'LEFT'; X = 700; Y = 52 },
        @{ View = 'right'; Label = 'RIGHT'; X = 1050; Y = 52 },
        @{ View = 'top'; Label = 'TOP'; X = 0; Y = 438 },
        @{ View = 'bottom'; Label = 'BOTTOM'; X = 350; Y = 438 },
        @{ View = 'iso'; Label = 'ISO'; X = 700; Y = 438 }
    )
    foreach ($view in $views) {
        $path = Join-Path $RenderDirectory "hp4\$($view.View).png"
        Draw-Cell $viewsGraphics $path $view.Label $view.X $view.Y 350 350
    }
    $viewsBitmap.Save(
        (Join-Path $OutputDirectory 'tower_reference_seven_views.png'),
        [System.Drawing.Imaging.ImageFormat]::Png
    )
}
finally {
    $viewsGraphics.Dispose()
    $viewsBitmap.Dispose()
}

Write-Host "Formal Tower reference sheets refreshed: $OutputDirectory"
