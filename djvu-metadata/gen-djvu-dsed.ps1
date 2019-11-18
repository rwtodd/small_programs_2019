<#
.Synopsis
Converts an input file into a djvused script.

.Example
gen-djvu-dsed.ps1 marks.txt
#>
Param(
  [Parameter(Mandatory=$true)] [System.IO.FileInfo] $src
)

$djvuPages = @{ }        # hash from book page names to djvu pages
[Int32] $djvuPage = -1   # the last recorded djvuPage
$bookPre = ""           # the last recorded book page, prefix part
[Int32]$bookNum = -1    # the last recorded book page, numeric part

$marks = [System.Collections.ArrayList]@()       # tracks the bookmarks we've seen
$metaFile = [System.Text.StringBuilder]::new()   # holds metadata
$pagesFile = [System.Text.StringBuilder]::new()  # holds all our output

# helper function to increase $djvuPage and $bookNum in tandem
function Inc-LastPage {
  if ($script:djvuPage -ge 1) {
    $script:djvuPage += 1
    if ($script:bookNum -eq -1) {
       $script:bookNum = 2
    } else {
       $script:bookNum += 1
    }
  }
}

# Helper function to divide a bookpage into its prefix and suffix
function Split-BookPage {
   Param($bp)
   switch -Regex ($bp) {
      '^\d+$' {
          $ans = @("",$matches[0])
      }
      '^\S*\D$' {
          $ans = @($matches[0],-1)
      }
      '^(\S*\D)(\d+)$' {
          $ans = @($matches[1],[int]$matches[2])
      }
   }
   return $ans
}

switch -Regex -File $src {
  # comment line or blank line
  '^\s*#|^\s*$' { }

  # Metadata
  '^\s*[Mm]eta\s+([^:]+):\s+(.*?)\s*$' {
    [void]$metaFile.AppendLine("$($matches[1])`t`"$($matches[2])`"")
  }

  # Page title
  '^\s*[Dd]jvu\s+(\d+)\s+(?:=|is)\s+[Bb]ook\s+(\S+)\s*$' {
    [Int32] $tgtPage = $matches[1]
    if ($tgtPage -le $djvuPage) { 
      Write-Error "Setting djvu $tgtPage after $djvuPage isn't allowed!"
      exit 1 
    }
    $tgtBook = $matches[2]
    Inc-LastPage
    if ($djvuPage -gt 0) {
      while ($djvuPage -lt $tgtPage) {
        $djvuPages.Add("$bookPre$bookNum", $djvuPage)
        [void]$pagesFile.AppendLine("select $djvuPage ; set-page-title `"$bookPre$bookNum`"")
        Inc-LastPage
      }
    }
    $djvuPages.Add($tgtBook, $tgtPage)
    [void]$pagesFile.AppendLine("select $tgtPage ; set-page-title `"$tgtBook`"")
    $djvuPage = $tgtPage
    ($bookPre,$bookNum) = Split-BookPage $tgtBook
  }

  # Bookmark page
  '^(\S+)\s+(.*?)\s*$' { 
    $mpage = $matches[1]
    $mtitle = $matches[2]
    if ($mpage -notmatch "^([Dd]jvu|[Mm]eta|#)")  {
      [void]$marks.Add( @{ "page"=$mpage; "title"=$mtitle } )
    }
  }

  # Anything else is an error!
  default { Write-Error "Bad line! <$_>"; exit 1 }
}

# now, write the output if all was well...
if ($metaFile.Length -gt 0) {
  [void]$pagesFile.AppendLine("select; set-meta")
  [void]$pagesFile.Append($metaFile.ToString()) 
  [void]$pagesFile.AppendLine(".")
}

if ($marks.Length -gt 0) {
  [void]$pagesFile.AppendLine("select; set-outline")
  [void]$pagesFile.AppendLine("(bookmarks")  
  foreach ($mark in $marks) {
    $djp = $djvuPages[$mark["page"]]
    if (-not $djp) {
       ($mpPre, $mpNum) = Split-BookPage $mark["page"]
       if($mpPre) {
          Write-Error "Bookmark $mpPre$mpNum not found!"
          exit 1 
       } else {
          $djp = $mpNum
       }
    }
    [void]$pagesFile.AppendLine("(`"$($mark["title"])`" `"#$djp`")")
  }
  [void]$pagesFile.AppendLine(")")  
  [void]$pagesFile.AppendLine(".")
}

$pagesFile.ToString() | Set-Content -LiteralPath "$src.dsed" -Encoding UTF8NoBOM
