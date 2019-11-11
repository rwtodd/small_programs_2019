# This is just the deployment script I use on my machines... where you put the binaries
# is your business.
$progName = "gen-dsed"

dotnet publish GenDSed.sln -c Release
$tgtDir = Join-Path (Resolve-Path "~") bin "_$progName"
$tgtScript = Join-Path (Resolve-Path "~") bin "$progName.ps1"
$relativeExe = Join-Path `$PSScriptRoot "_$progName" "$progName.exe"

if (Test-Path $tgtDir) {
  Remove-Item -Force -Recurse $tgtDir
}
if (Test-Path $tgtScript) {
  Remove-Item -Force $tgtScript
}

Write-Output "Writing to $tgtScript"
Copy-Item -Recurse -LiteralPath bin\Release\netcoreapp3.0\publish -Destination $tgtDir
Set-Content -Path $tgtScript -Value @"
& "$relativeExe" `@args
"@
