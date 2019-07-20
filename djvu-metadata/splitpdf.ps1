Param (
    [Parameter(Mandatory=$true)][System.IO.FileInfo] $pdf,
    [Int32] $dpi = 600,
    [Int32] $unit = 25,
    [String] $device = "tiff24nc",
    [Int32] $testPage = 0
)

$gs = 'C:\Program Files\gs\gs9.24\bin\gswin64c.exe'  # location on my machine

function New-Tiff {
    Param (     
        [Int32] $fp,  # first page
        [Int32] $lp   # last page
    )
    $ofile = 'page-{0:D4}.tiff' -f $fp
    if (-not (Test-Path -LiteralPath $ofile)) {
        Write-Host -ForegroundColor Yellow "FirstPage $fp; LastPage $lp"
        & $gs "-sDEVICE=$device" "-dFirstPage=$fp" "-dLastPage=$lp" "-r${dpi}x${dpi}" "-o" $ofile $pdf | Out-Null
    } else {
        Write-Host -ForegroundColor Red "File <$ofile> already exists."
    }
}

if($testPage -gt 0) {
    Write-Host "Testing <$pdf> page $testPage at $dpi dpi."
    New-Tiff -fp $testPage -lp $testPage    
    exit 0
}

Write-Host "Splitting <$pdf> into units of $unit pages at $dpi dpi."
$wslpath = & wsl.exe wslpath ($pdf -replace '\\','\\\\')
& wsl.exe pdfinfo `"$wslpath`" | `
    select-string -pattern '^Pages:\s+(\d+)' | `
    select-object -First 1 | `
    ForEach-Object { [Int32] $pages = $_.Matches[0].Groups[1].ToString() }
Write-Host -ForegroundColor Yellow "There are $pages pages in $pdf.`n"
for ($p = 1 ; $p -le $pages ; $p += $unit) {
    New-Tiff -fp $p -lp ($p + $unit - 1)
}
