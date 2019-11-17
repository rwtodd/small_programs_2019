<#
.Synopsis
This script reads all the flac files in the current directory, and
converts them to ogg vorbis files.
.Description
FFMPEG is used to do the conversion.  The quality rating is set to 8.

.Example
flac-to-ogg.ps1
#>
$FFMPEG="C:\Program Files\ffmpeg-4.1-win64-static\bin\ffmpeg.exe" 
Get-ChildItem *.flac | ForEach-Object -Process { 
   $ogg = $_ -replace '.flac$','.ogg'
   if (-not (Test-Path $ogg)) {
     & $FFMPEG -i $_ -vn "-c:a" libvorbis "-q:a" 8 $ogg
   }
}
