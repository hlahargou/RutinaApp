Add-Type -AssemblyName System.Drawing

function New-Icon {
    param(
        [int]$Size,
        [string]$OutPath,
        [bool]$Maskable = $false
    )

    $bmp = New-Object System.Drawing.Bitmap $Size, $Size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    # Fondo (dark) - toda la superficie
    $bgColor = [System.Drawing.Color]::FromArgb(255, 14, 15, 17)
    $bgBrush = New-Object System.Drawing.SolidBrush $bgColor
    $g.FillRectangle($bgBrush, 0, 0, $Size, $Size)

    # Para "any", agregamos esquinas visuales redondeadas con un rect de fondo tono acento tenue
    if (-not $Maskable) {
        $borderColor = [System.Drawing.Color]::FromArgb(255, 42, 45, 53)
        $borderPen = New-Object System.Drawing.Pen $borderColor, ($Size * 0.012)
        $inset = [int]($Size * 0.06)
        $rect = New-Object System.Drawing.Rectangle $inset, $inset, ($Size - 2*$inset), ($Size - 2*$inset)
        $g.DrawRectangle($borderPen, $rect)
        $borderPen.Dispose()
    }

    # Texto "R" en color acento
    $fgColor = [System.Drawing.Color]::FromArgb(255, 200, 240, 96)
    $fgBrush = New-Object System.Drawing.SolidBrush $fgColor

    # Para maskable, la letra debe estar dentro del safe zone (80% central)
    $fontSize = if ($Maskable) { [int]($Size * 0.45) } else { [int]($Size * 0.62) }
    $font = New-Object System.Drawing.Font "Arial Black", $fontSize, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)

    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    $rectF = New-Object System.Drawing.RectangleF 0, 0, $Size, $Size
    $g.DrawString("R", $font, $fgBrush, $rectF, $sf)

    # Pequeño puntito acento debajo (marca visual)
    if (-not $Maskable) {
        $dotSize = [int]($Size * 0.05)
        $dotX = [int]($Size * 0.5 - $dotSize / 2)
        $dotY = [int]($Size * 0.82)
        $g.FillEllipse($fgBrush, $dotX, $dotY, $dotSize, $dotSize)
    }

    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $font.Dispose()
    $fgBrush.Dispose()
    $bgBrush.Dispose()
    $g.Dispose()
    $bmp.Dispose()

    Write-Host "Generado: $OutPath ($Size x $Size)"
}

$base = $PSScriptRoot
New-Icon -Size 192 -OutPath (Join-Path $base "icon-192.png") -Maskable $false
New-Icon -Size 512 -OutPath (Join-Path $base "icon-512.png") -Maskable $false
New-Icon -Size 512 -OutPath (Join-Path $base "icon-maskable-512.png") -Maskable $true

Write-Host "`nListo. Iconos generados en: $base"
