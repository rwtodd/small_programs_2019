Param(
  [Parameter(Mandatory=$true)] [System.IO.FileInfo] $src
)

$prefix = 'p'            # prefix for page titles
$numeric = $false        # are the page titles numeric? 
[Int32] $djvuPage = -1   # the current djvu page
$bookPage = -1           # the current book page (may not be numeric)

$metaFile = [System.Text.StringBuilder]::new()   # holds metadata
$marksFile = [System.Text.StringBuilder]::new()  # holds bookmarks
$pagesFile = [System.Text.StringBuilder]::new()  # holds page info

function Write-Page-Title {
  $pfx = "" ; if($numeric) { $pfx = $prefix }
  [void]$pagesFile.AppendLine("select $djvuPage; set-page-title `"$pfx$bookPage`"")
  $script:djvuPage++
  if($numeric) { ([Int32] $script:bookPage)++ }
}

switch -Regex -File $src {
  # comment line or blank line
  '^\s*#|^\s*$' {   }

  # Metadata
  '^\s*[Mm]eta\s+([^:]+):\s+(.*?)\s*$' {
    [void]$metaFile.AppendLine("$($matches[1])`t`"$($matches[2])`"")
  }

  # Page title
  '^\s*[Dd]jvu\s+(\d+)\s+(?:=|is)\s+[Bb]ook\s+(\S+)(?:\s+[Pp]refix\s+(.*?))?\s*$' {
    [Int32] $tgtPage = $matches[1]
    if ($tgtPage -lt $djvuPage) { 
      Write-Error "Setting djvu $tgtPage after $djvuPage isn't allowed!"
      # exit 1 
    }
    while ($numeric -and $djvuPage -lt $tgtPage) { Write-Page-Title }
    $djvuPage, $bookPage = $tgtPage, $matches[2] 
    if ($matches[3]) { $prefix = $matches[3] }
    if ($bookPage -match '^\d+$') {
      $numeric = $true
      $bookPage = [Int32] $bookPage
      $offset = $djvuPage - $bookPage
    } else {
      $numeric = $false
      $offset = 0
    }
    Write-Page-Title
  }

  # Bookmark page
  '^(\d+)\s+(.*?)\s*$' { 
    [Int32] $markPage = $matches[1]
    [void]$marksFile.AppendLine("(`"$($matches[2])`" `"#$($markPage + $offset)`")")
  }

  # Anything else is an error!
  default { Write-Error "Bad line! <$_>"; exit 1 }
}

# now, write the output if all was well...
if ($marksFile.Length -gt 0) {
  [void]$pagesFile.AppendLine("select; set-outline marks.dsed")
  "(bookmarks`r`n{0})" -f $marksFile.ToString() | Set-Content -LiteralPath marks.dsed -Encoding UTF8NoBOM
}
if ($metaFile.Length -gt 0) {
  [void]$pagesFile.AppendLine("select; set-meta meta.dsed")
  $metaFile.ToString() | Set-Content -LiteralPath meta.dsed -Encoding UTF8NoBOM
}
$pagesFile.ToString() | Set-Content -LiteralPath pages.dsed -Encoding UTF8NOBOM
