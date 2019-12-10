# deploy the program... just an example of what I use on my machine...
$project = "gen-dsed"
$version = "1.0.0"

lein uberjar
if (-not $?) {
   Write-Error "lein failed..."
   exit -1
}

$tgtDir = Join-Path (Resolve-Path "~") bin "_$project"
$tgtJar = Join-Path $tgtDir "$project-$version.jar"
$prjJar = Join-Path "target" "uberjar" "${project}-${version}-standalone.jar"

$tgtScript = Join-Path (Resolve-Path "~") bin "$project.ps1"
if (Test-Path $tgtDir) {
   Remove-Item -Force -Recurse $tgtDir
}
if (Test-Path $tgtScript) {
   Remove-Item -Force $tgtScript
}

Write-Output "Writing to $tgtScript"
New-Item -Type Directory -Path $tgtDir
Copy-Item -LiteralPath $prjJar -Destination $tgtJar
Set-Content -Path $tgtScript -Value @"
& java -jar $tgtJar `@args
"@
