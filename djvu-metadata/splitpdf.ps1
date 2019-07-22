<#
.Synopsis
This script splits a pdf file into a set of TIFF files.
.Description
Ghostscript is used to output TIFF files, and parameters are offered
to control aspects such as the device, dpi, and compression used.

.Parameter device
The Ghostscript device to use for output (default tiff24nc).
.Parameter dpi
The output dpi (default 600).
.Parameter prefix
A prefix for the output filename (defualt 'page').
.Parameter unit
The number of pages per TIFF file (default 100).
.Parameter testPage
When provided, this parameter indicates that the script should only
output the given page. This way, a single page can be inspected prior
to spending time splitting the entire pdf.
.Parameter gsArgs
An array of additional arguments to Ghostscript (default "-sCompression=lzw").

.Example
splitpdf.ps1 file.pdf

Splits a pdf with default settings (600dpi, 25 pages per TIFF, 24-bit color LZW compressed).
#>
Param (
    [Parameter(Mandatory=$true)][System.IO.FileInfo] $pdf,
    [Int32] $dpi = 600,
    [Int32] $unit = 100,
    [String] $device = "tiff24nc",
    [String] $prefix = "page",
    [String[]] $gsArgs = @("-sCompression=lzw"),
    [Int32] $testPage = 0
)

$gs = 'C:\Program Files\gs\gs9.24\bin\gswin64c.exe'  # location on my machine

function New-Tiff {
    Param (     
        [Int32] $fp,  # first page
        [Int32] $lp   # last page
    )
    $ofile = '{0}-{1:D4}.tiff' -f $prefix,$fp
    if (-not (Test-Path -LiteralPath $ofile)) {
        Write-Host -ForegroundColor Yellow "FirstPage $fp; LastPage $lp"
        & $gs "-sDEVICE=$device" "-dFirstPage=$fp" "-dLastPage=$lp" `
           "-r${dpi}x${dpi}" @gsArgs "-o" $ofile $pdf | Out-Null
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
